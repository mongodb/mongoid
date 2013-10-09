module Mongoid
  module Sessions
    module StorageOptions
      extend ActiveSupport::Concern

      included do

        cattr_accessor :storage_options, instance_writer: false do
          self.storage_options_defaults
        end
      end

      module ClassMethods

        # Give this model specific custom default storage options.
        #
        # @example Store this model by default in "artists"
        #   class Band
        #     include Mongoid::Document
        #     store_in collection: "artists"
        #   end
        #
        # @example Store this model by default in the sharded db.
        #   class Band
        #     include Mongoid::Document
        #     store_in database: "echo_shard"
        #   end
        #
        # @example Store this model by default in a different session.
        #   class Band
        #     include Mongoid::Document
        #     store_in session: "secondary"
        #   end
        #
        # @example Store this model with a combination of options.
        #   class Band
        #     include Mongoid::Document
        #     store_in collection: "artists", database: "secondary"
        #   end
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
        def store_in(options)
          Validators::Storage.validate(self, options)
          self.storage_options.merge!(options)
        end

        def reset_storage_options!
          self.storage_options = storage_options_defaults.dup
        end

        def storage_options_defaults
          {
            collection: self.name.collectionize.to_sym,
            session: :default,
            database: Mongoid.sessions[:default][:database]
          }
        end

        # Get the name of the collection this model persists to.
        #
        # @example Get the collection name.
        #   Model.collection_name
        #
        # @return [ Symbol ] The name of the collection.
        #
        # @since 3.0.0
        def collection_name
          __evaluate__(self.storage_options[:collection])
        end

        # Get the session name for the model.
        #
        # @example Get the session name.
        #   Model.session_name
        #
        # @return [ Symbol ] The name of the session.
        #
        # @since 3.0.0
        def session_name
          __evaluate__(self.storage_options[:session])
        end

        def database_name
          __evaluate__(self.storage_options[:database])
        end

        private

        # Eval the provided value, either byt calling it if it responds to call
        # or returning the value itself.
        #
        # @api private
        #
        # @example Evaluate the name.
        #   Model.__evaluate__(:name)
        #
        # @param [ String, Symbol, Proc ] name The name.
        #
        # @return [ Symbol ] The value as a symbol.
        #
        # @since 3.1.0
        def __evaluate__(name)
          return nil unless name
          name.respond_to?(:call) ? name.call.to_sym : name.to_sym
        end

      end
    end
  end
end
