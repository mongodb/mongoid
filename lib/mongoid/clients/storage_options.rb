# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Clients
    module StorageOptions
      extend ActiveSupport::Concern

      included do

        cattr_accessor :storage_options, instance_writer: false do
          storage_options_defaults
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
        # @example Store this model by default in a different client.
        #   class Band
        #     include Mongoid::Document
        #     store_in client: "analytics"
        #   end
        #
        # @example Store this model with a combination of options.
        #   class Band
        #     include Mongoid::Document
        #     store_in collection: "artists", database: "music"
        #   end
        #
        # @param [ Hash ] options The storage options.
        #
        # @option options [ String | Symbol ] :collection The collection name.
        # @option options [ String | Symbol ] :database The database name.
        # @option options [ String | Symbol ] :client The client name.
        #
        # @return [ Class ] The model class.
        #
        # @since 3.0.0
        def store_in(options)
          Validators::Storage.validate(self, options)
          storage_options.merge!(options)
        end

        # Reset the store_in options
        #
        # @example Reset the store_in options
        #   Model.reset_storage_options!
        #
        # @since 4.0.0
        def reset_storage_options!
          self.storage_options = storage_options_defaults.dup
          PersistenceContext.clear(self)
        end

        # Get the default storage options.
        #
        # @example Get the default storage options.
        #   Model.storage_options_defaults
        #
        # @return [ Hash ] Default storage options.
        #
        # @since 4.0.0
        def storage_options_defaults
          {
            collection: name.collectionize.to_sym,
            client: :default
          }
        end
      end
    end
  end
end
