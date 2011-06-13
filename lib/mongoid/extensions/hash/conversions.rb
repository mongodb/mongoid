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
          #   Hash.try_bson({})
          #
          # @param [ Hash ] value The hash.
          #
          # @return [ Hash ] The provided hash.
          #
          # @since 1.0.0
          def try_bson(value)
            value
          end

          # Returns the hash value.
          #
          # @example Cast the hash.
          #   Hash.from_bson({})
          #
          # @param [ Hash ] value The hash.
          #
          # @return [ Hash ] The provided hash.
          #
          # @since 1.0.0
          def from_bson(value)
            value
          end
        end
      end
    end
  end
end
