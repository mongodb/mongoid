# frozen_string_literal: true

module Mongoid
  module Clients
    module Validators

      # Validates the options passed to :store_in.
      module Storage
        extend self

        # The valid options for storage.
        VALID_OPTIONS = [ :collection, :database, :client ].freeze

        # Validate the options provided to :store_in.
        #
        # @example Validate the options.
        #   Storage.validate(:collection_name)
        #
        # @param [ Class ] klass The model class.
        # @param [ Hash | String | Symbol ] options The provided options.
        def validate(klass, options)
          valid_keys?(options) or raise Errors::InvalidStorageOptions.new(klass, options)
          valid_parent?(klass) or raise Errors::InvalidStorageParent.new(klass)
        end

        private
        # Determine if the current klass is valid to change store_in
        # options
        #
        # @api private
        #
        # @param [ Class ] klass
        #
        # @return [ true | false ] If the class is valid.
        def valid_parent?(klass)
          !klass.superclass.include?(Mongoid::Document)
        end

        # Determine if all keys in the options hash are valid.
        #
        # @api private
        #
        # @example Are all keys valid?
        #   validator.valid_keys?({ collection: "name" })
        #
        # @param [ Hash ] options The options hash.
        #
        # @return [ true | false ] If all keys are valid.
        def valid_keys?(options)
          return false unless options.is_a?(::Hash)
          options.keys.all? do |key|
            VALID_OPTIONS.include?(key)
          end
        end
      end
    end
  end
end
