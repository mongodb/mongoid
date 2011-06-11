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
          #   Set.get([])
          #
          # @param [ Array ] value The array to convert.
          #
          # @return [ Set ] The converted set.
          #
          # @since 1.0.0
          def get(value)
            ::Set.new(value)
          end

          # Convert the set to an array for mongo.
          #
          # @example Convert the set.
          #   Set.set(set)
          #
          # @param [ Set ] value The set to convert.
          #
          # @return [ Array ] The converted array.
          #
          # @since 1.0.0
          def set(value)
            value.to_a
          end
        end
      end
    end
  end
end
