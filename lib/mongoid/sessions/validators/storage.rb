# encoding: utf-8
module Mongoid
  module Sessions
    module Validators

      # Validates the options passed to :store_in.
      module Storage
        extend self

        VALID_OPTIONS = [ :collection, :database, :session ]

        # Validate the options provided to :store_in.
        #
        # @example Validate the options.
        #   Storage.validate(:collection_name)
        #
        # @param [ Hash, String, Symbol ] options The provided options.
        #
        # @since 3.0.0
        def validate(options)
          if !options.is_a?(::Hash) || !valid_keys?(options)
            raise Errors::InvalidStorageOptions.new(options)
          end
        end

        private

        # Determine if all keys in the options hash are valid.
        #
        # @api private
        #
        # @example Are all keys valid?
        #   validator.valid_keys?({ collection: "name" })
        #
        # @param [ Hash ] options The options hash.
        #
        # @return [ true, false ] If all keys are valid.
        #
        # @since 3.0.0
        def valid_keys?(options)
          options.keys.all? do |key|
            VALID_OPTIONS.include?(key)
          end
        end
      end
    end
  end
end
