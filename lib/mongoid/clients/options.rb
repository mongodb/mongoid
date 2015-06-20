# encoding: utf-8
module Mongoid
  module Clients
    module Options
      extend ActiveSupport::Concern
      extend Gem::Deprecate

      # Tell the next persistance operation to store in a specific collection,
      # database or client.
      #
      # @example Save the current document to a different collection.
      #   model.with(collection: "secondary").save
      #
      # @example Save the current document to a different database.
      #   model.with(database: "secondary").save
      #
      # @example Save the current document to a different client.
      #   model.with(client: "replica_set").save
      #
      # @example Save with a combination of options.
      #   model.with(client: "sharded", database: "secondary").save
      #
      # @note This method will instantiate a new client under the covers and
      #   can be expensive. It is also recommended that the user manually
      #   closes the extra client after using it, otherwise an excessive amount
      #   of connections to the server will be eventually opened.
      #
      # @param [ Hash ] options The storage options.
      #
      # @option options [ String, Symbol ] :collection The collection name.
      # @option options [ String, Symbol ] :database The database name.
      # @option options [ String, Symbol ] :client The client name.
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

      def mongo_client
        if persistence_options
          if persistence_options[:client]
            client = Clients.with_name(persistence_options[:client])
          else
            client = Clients.with_name(self.class.client_name)
            client.use(self.class.database_name)
          end
          client.with(persistence_options.reject{ |k, v| k == :collection || k == :client })
        end
      end
      alias :mongo_session :mongo_client
      deprecate :mongo_session, :mongo_client, 2015, 12

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
        extend Gem::Deprecate
        include Threaded

        def client_name
          if persistence_options && v = persistence_options[:client]
            return v.to_sym
          end
          super
        end
        alias :session_name :client_name
        deprecate :session_name, :client_name, 2015, 12

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
        # database or client.
        #
        # @example Create a document in a different collection.
        #   Model.with(collection: "secondary").create(name: "test")
        #
        # @example Create a document in a different database.
        #   Model.with(database: "secondary").create(name: "test")
        #
        # @example Create a document in a different client.
        #   Model.with(client: "secondary").create(name: "test")
        #
        # @example Create with a combination of options.
        #   Model.with(client: "sharded", database: "secondary").create
        #
        # @param [ Hash ] options The storage options.
        #
        # @option options [ String, Symbol ] :collection The collection name.
        # @option options [ String, Symbol ] :database The database name.
        # @option options [ String, Symbol ] :client The client name.
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
