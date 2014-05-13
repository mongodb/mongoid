# encoding: utf-8
module Mongoid
  module Sessions
    module Options
      extend ActiveSupport::Concern

      # Tell the next persistance operation to store in a specific collection,
      # database or session.
      #
      # @example Save the current document to a different collection.
      #   model.with(collection: "secondary").save
      #
      # @example Save the current document to a different database.
      #   model.with(database: "secondary").save
      #
      # @example Save the current document to a different session.
      #   model.with(session: "replica_set").save
      #
      # @example Save with a combination of options.
      #   model.with(session: "sharded", database: "secondary").save
      #
      # @param [ Hash ] options The storage options.
      #
      # @option options [ String, Symbol ] :collection The collection name.
      # @option options [ String, Symbol ] :database The database name.
      # @option options [ String, Symbol ] :session The session name.
      #
      # @return [ Document ] The current document.
      #
      # @since 3.0.0
      def with(options)
        @persistence_options = options
        self
      end

      def persistence_options
        @persistence_options
      end

      def mongo_session
        if persistence_options
          session_name = persistence_options[:session] || self.class.session_name
          Sessions.with_name(session_name).with(persistence_options)
        end
      end

      def collection_name
        if persistence_options && v = persistence_options[:collection]
          return v.to_sym
        end
      end

      module Threaded

        # Get the persistence options for the current thread.
        #
        # @example Get the persistence options.
        #   Threaded.persistence_options(Band)
        #
        # @param [ Class ] klass The model class.
        #
        # @return [ Hash ] The current persistence options.
        #
        # @since 4.0.0
        def persistence_options(klass = self)
          Thread.current["[mongoid][#{klass}]:persistence-options"]
        end

        private
        # Set the persistence options on the current thread.
        #
        # @api private
        #
        # @example Set the persistence options.
        #   Threaded.set_persistence_options(Band, { safe: { fsync: true }})
        #
        # @param [ Class ] klass The model class.
        # @param [ Hash ] options The persistence options.
        #
        # @return [ Hash ] The persistence options.
        #
        # @since 4.0.0
        def set_persistence_options(klass, options)
          Thread.current["[mongoid][#{klass}]:persistence-options"] = options
        end
      end

      module ClassMethods
        include Threaded

        def session_name
          if persistence_options && v = persistence_options[:session]
            return v.to_sym
          end
          super
        end

        def collection_name
          if persistence_options && v = persistence_options[:collection]
            return v.to_sym
          end
          super
        end

        def database_name
          if persistence_options && v = persistence_options[:database]
            return v.to_sym
          end
          super
        end

        # Tell the next persistance operation to store in a specific collection,
        # database or session.
        #
        # @example Create a document in a different collection.
        #   Model.with(collection: "secondary").create(name: "test")
        #
        # @example Create a document in a different database.
        #   Model.with(database: "secondary").create(name: "test")
        #
        # @example Create a document in a different session.
        #   Model.with(session: "secondary").create(name: "test")
        #
        # @example Create with a combination of options.
        #   Model.with(session: "sharded", database: "secondary").create
        #
        # @param [ Hash ] options The storage options.
        #
        # @option options [ String, Symbol ] :collection The collection name.
        # @option options [ String, Symbol ] :database The database name.
        # @option options [ String, Symbol ] :session The session name.
        #
        # @return [ Class ] The model class.
        #
        # @since 3.0.0
        def with(options)
          Proxy.new(self, (persistence_options || {}).merge(options))
        end
      end

      class Proxy < BasicObject
        include Threaded

        undef_method :==

        def initialize(target, options)
          @target = target
          @options = options
        end

        def persistence_options
          @options
        end

        def respond_to?(*args)
          @target.respond_to?(*args)
        end

        def method_missing(name, *args, &block)
          set_persistence_options(@target, @options)
          ret = @target.send(name, *args, &block)
          if Mongoid::Criteria == ret.class
            ret.with @options
          end
          ret
        ensure
          set_persistence_options(@target, nil)
        end

        def send(symbol, *args)
          __send__(symbol, *args)
        end

        def self.const_missing(name)
          ::Object.const_get(name)
        end
      end
    end
  end
end
