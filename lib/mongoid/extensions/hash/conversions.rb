# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:

      # Handles the conversion of hashes to and from mongo.
      module Conversions
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:

          # Returns the hash value.
          #
          # @example Cast the hash.
          #   Hash.get({})
          #
          # @param [ Hash ] value The hash.
          #
          # @return [ Hash ] The provided hash.
          #
          # @since 1.0.0
          def get(value)
            value
          end

          # Returns the hash value.
          #
          # @example Cast the hash.
          #   Hash.set({})
          #
          # @param [ Hash ] value The hash.
          #
          # @return [ Hash ] The provided hash.
          #
          # @since 1.0.0
          def set(value)
            value
          end
        end
      end
    end
  end
end
