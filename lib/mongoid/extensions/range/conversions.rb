# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Range #:nodoc:

      # Handles conversions of ranges to and from mongo.
      module Conversions
        extend ActiveSupport::Concern

        # Convert a range to a hash.
        #
        # @example Convert to a hash.
        #   1...3.to_hash
        #
        # @return [ Hash ] The range with min and max in the hash.
        #
        # @since 2.0.0
        def to_hash
          { "min" => min, "max" => max }
        end

        module ClassMethods #:nodoc:

          # Convert the hash to a range.
          #
          # @example Convert the hash.
          #   Range.get({ "min" => 1, "max" => 10 })
          #
          # @param [ Hash ] value The hash to convert.
          #
          # @return [ Range, nil ] The converted range.
          #
          # @since 2.0.0
          def get(value)
            value.nil? ? nil : ::Range.new(value["min"], value["max"])
          end

          # Convert the range to a hash.
          #
          # @example Convert the range.
          #   Range.set(1..3)
          #
          # @param [ Range ] value The range to convert.
          #
          # @return [ Hash ] The range as a hash.
          #
          # @since 2.0.0
          def set(value)
            value.nil? ? nil : value.to_hash
          end
        end
      end
    end
  end
end
