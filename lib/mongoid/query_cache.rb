module Mongoid
  module QueryCache
    class << self

      def cache_table
        Thread.current['[mongoid]:query_cache'] ||= Hash.new
      end

      def clear_cache
        Thread.current['[mongoid]:query_cache'] = nil
      end

      def enabled=(value)
        Thread.current['[mongoid]:query_cache:enabled'] = value
      end

      def enabled?
        !!Thread.current['[mongoid]:query_cache:enabled']
      end

      def cache
        enabled = QueryCache.enabled?
        QueryCache.enabled = true
        yield
      ensure
        QueryCache.enabled = enabled
      end
    end

    class Middleware

      def initialize(app)
        @app = app
      end

      def call(env)
        QueryCache.cache { @app.call(env) }
      ensure
        QueryCache.clear_cache
      end
    end

    module Base # :nodoc:

      def alias_query_cache_clear(*method_names)
        method_names.each do |method_name|
          class_eval <<-CODE, __FILE__, __LINE__ + 1
              def #{method_name}_with_clear_cache(*args)
                QueryCache.clear_cache
                #{method_name}_without_clear_cache(*args)
              end
            CODE

          alias_method_chain method_name, :clear_cache
        end
      end
    end

    module Query # :nodoc:
      def self.included(base)
        base.extend QueryCache::Base
        base.alias_method_chain(:cursor, :cache)
        base.alias_query_cache_clear(:remove, :remove_all, :update, :update_all, :upsert)
      end

      def cursor_with_cache
        CachedCursor.new(session, operation)
      end
    end

    module Collection # :nodoc:
      def self.included(base)
        base.extend QueryCache::Base
        base.alias_query_cache_clear(:insert)
      end
    end

    class CachedCursor < Moped::Cursor # :nodoc:

      def load_docs
        with_cache { super }
      end

      private
      def with_cache
        return yield unless QueryCache.enabled?
        return yield if @collection =~ /^system./
        key = [@database, @collection, @selector]
        QueryCache.cache_table[key] ||= yield
      end
    end
  end
end

Moped::Query.__send__(:include, Mongoid::QueryCache::Query)
Moped::Collection.__send__(:include, Mongoid::QueryCache::Collection)
