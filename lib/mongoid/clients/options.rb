# encoding: utf-8
module Mongoid
  module Clients
    module Options
      extend ActiveSupport::Concern

      # Tell the next persistence operation to store in a specific collection,
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
        tmp = persistence_options
        if opts = tmp && tmp.dup
          if opts[:client]
            client = Clients.with_name(opts[:client])
          else
            client = Clients.with_name(self.class.client_name)
            client.use(self.class.database_name)
          end
          client.with(opts.reject{ |k, v| k == :collection || k == :client })
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

        # Get the client with special options for the current thread.
        #
        # @example Get the client with options.
        #   Threaded.client_with_options(Band)
        #
        # @param [ Class ] klass The model class.
        #
        # @return [ Mongo::Client ] The client.
        #
        # @since 5.1.0
        def client_with_options(klass = self)
          Thread.current["[mongoid][#{klass}]:mongo-client"]
        end

        private
        # Set the persistence options on the current thread.
        #
        # @api private
        #
        # @example Set the persistence options.
        #   Threaded.set_persistence_options(Band, { write: { w: 3 }})
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

        # Unset the persistence options on the current thread.
        #
        # @api private
        #
        # @example Unset the persistence options.
        #   Threaded.unset_persistence_options(Band)
        #
        # @param [ Class ] klass The model class.
        #
        # @return [ nil ] nil.
        #
        # @since 5.1.0
        def unset_persistence_options(klass)
          Thread.current["[mongoid][#{klass}]:persistence-options"] = nil
        end

        # Set the persistence options and client with those options on the current thread.
        # Note that a client will only be set if its cluster differs from the cluster of the
        # original client.
        #
        # @api private
        #
        # @example Set the persistence options and client with those options on the current thread.
        #   Threaded.set_options(Band, { write: { w: 3 }})
        #
        # @param [ Class ] klass The model class.
        # @param [ Mongo::Client ] client The client with options.
        #
        # @return [ Mongo::Client, nil ] The client or nil if the cluster does not change.
        #
        # @since 5.1.0
        def set_options(klass, options)
          original_cluster = mongo_client.cluster
          set_persistence_options(klass, options)
          m = mongo_client
          set_client_with_options(klass, m) unless m.cluster.equal?(original_cluster)
        end

        # Set the client with special options on the current thread.
        #
        # @api private
        #
        # @example Set the client with options.
        #   Threaded.set_client_with_options(Band, client)
        #
        # @param [ Class ] klass The model class.
        # @param [ Mongo::Client ] client The client with options.
        #
        # @return [ Mongo::Client ] The client.
        #
        # @since 5.1.0
        def set_client_with_options(klass, client)
          Thread.current["[mongoid][#{klass}]:mongo-client"] = client
        end

        # Unset the client with special options on the current thread.
        #
        # @api private
        #
        # @example Unset the client with options.
        #   Threaded.unset_client_with_options(Band)
        #
        # @param [ Class ] klass The model class.
        #
        # @return [ nil ] nil.
        #
        # @since 5.1.0
        def unset_client_with_options(klass)
          if client = Thread.current["[mongoid][#{klass}]:mongo-client"]
            client.close
            Thread.current["[mongoid][#{klass}]:mongo-client"] = nil
          end
        end

        # Unset the persistence options and client with special options on the current thread.
        #
        # @api private
        #
        # @example Unset the persistence options and client with options.
        #   Threaded.unset_options(Band)
        #
        # @param [ Class ] klass The model class.
        #
        # @return [ nil ] nil.
        #
        # @since 5.1.0
        def unset_options(klass)
          unset_persistence_options(klass)
          unset_client_with_options(klass)
        end
      end

      module ClassMethods
        include Threaded

        def client_name
          if persistence_options && v = persistence_options[:client]
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

        # Tell the next persistence operation to store in a specific collection,
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
          if block_given?
            set_options(self, options)
            yield self
            unset_options(self)
          else
            Proxy.new(self, (persistence_options || {}).merge(options))
          end
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
          unset_persistence_options(@target)
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
