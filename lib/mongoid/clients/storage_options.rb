# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Clients

    # Mixin module included into Mongoid::Document which adds
    # the ability to set the collection in which to store the
    # document by default.
    module StorageOptions
      extend ActiveSupport::Concern

      included do
        class_attribute :storage_options, instance_accessor: false, default: storage_options_defaults
      end

      # Remembers the storage options that were active when the current object
      # was instantiated/created.
      #
      # @return [ Hash | nil ] the storage options that have been cached for
      #   this object instance (or nil if no storage options have been
      #   cached).
      #
      # @api private
      attr_accessor :remembered_storage_options

      # The storage options that apply to this record, consisting of both
      # the class-level declared storage options (e.g. store_in) merged with
      # any remembered storage options.
      #
      # @return [ Hash ] the storage options for the record
      #
      # @api private
      def storage_options
        self.class.storage_options.merge(remembered_storage_options || {})
      end

      # Saves the storage options from the current persistence context.
      #
      # @api private
      def remember_storage_options!
        return if Mongoid.legacy_persistence_context_behavior

        opts = persistence_context.requested_storage_options
        self.remembered_storage_options = opts if opts
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
        def store_in(options)
          Validators::Storage.validate(self, options)
          self.storage_options = self.storage_options.merge(options)
        end

        # Reset the store_in options
        #
        # @example Reset the store_in options
        #   Model.reset_storage_options!
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
