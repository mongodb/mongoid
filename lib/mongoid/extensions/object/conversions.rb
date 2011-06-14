# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:

      # This module converts objects into mongoid related objects.
      module Conversions
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:

          # Convert the object. Will either return the object as a document or
          # itself.
          #
          # @example Get the object.
          #   Object.get("testing")
          #
          # @param [ Object ] value The value to convert.
          #
          # @return [ Object, Document ] The converted object.
          #
          # @since 1.0.0
          def get(value)
            if value && respond_to?(:instantiate)
              instantiate(value)
            else
              value
            end
          end

          # Cast the object for storage.
          #
          # @example Convert the object to a storable state.
          #   Object.set(Person.new)
          #
          # @param [ Object, Document ] value The object to convert.
          #
          # @return [ Object, Hash ] The object converted.
          #
          # @since 1.0.0
          def set(value)
            value.respond_to?(:attributes) ? value.attributes : value
          end
        end
      end
    end
  end
end
