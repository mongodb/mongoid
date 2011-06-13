# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Set #:nodoc:

      # This module converts set into mongoid related objects.
      module Conversions
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:

          # Convert the array to a set.
          #
          # @example Convert the array.
          #   Set.try_bson([])
          #
          # @param [ Array ] value The array to convert.
          #
          # @return [ Set ] The converted set.
          #
          # @since 1.0.0
          def try_bson(value)
            ::Set.new(value)
          end

          # Convert the set to an array for mongo.
          #
          # @example Convert the set.
          #   Set.from_bson(set)
          #
          # @param [ Set ] value The set to convert.
          #
          # @return [ Array ] The converted array.
          #
          # @since 1.0.0
          def from_bson(value)
            value.to_a
          end
        end
      end
    end
  end
end
