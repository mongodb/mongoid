module Mongoid
  module QueryCache

    def self.cache_table
      Thread.current['[mongoid]:query_cache'] ||= Hash.new
    end

    module Base

      def alias_query_cache_clear(*method_names)
        method_names.each do |method_name|
          class_eval <<-CODE, __FILE__, __LINE__ + 1
              def #{method_name}_with_clear_cache(*args)
                Thread.current['[mongoid]:query_cache'] = nil
                #{method_name}_without_clear_cache(*args)
              end
            CODE

          alias_method_chain method_name, :clear_cache
        end
      end
    end

    module Query
      def self.included(base)
        base.extend QueryCache::Base
        base.alias_method_chain(:cursor, :cache)
        base.alias_query_cache_clear(:remove, :remove_all, :update, :update_all, :upsert)
      end

      def cursor_with_cache
        CachedCursor.new(session, operation)
      end
    end

    module Collection
      def self.included(base)
        base.extend QueryCache::Base
        base.alias_query_cache_clear(:insert)
      end
    end

    class CachedCursor < Moped::Cursor

      def load_docs
        with_cache { super }
      end

      private
      def with_cache
        return yield if @collection =~ /^system./
        key = [@database, @collection, @selector]
        QueryCache.cache_table[key] ||= yield
      end
    end
  end
end

Moped::Query.__send__(:include, Mongoid::QueryCache::Query)
Moped::Collection.__send__(:include, Mongoid::QueryCache::Collection)
