# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $inc operations.
    #
    # @since 4.0.0
    module Incrementable
      extend ActiveSupport::Concern

      # Increment the provided fields by the corresponding values. Values can
      # be positive or negative, and if no value exists for the field it will
      # be set with the provided value.
      #
      # @example Increment the fields.
      #   document.inc(score: 10, place: 1, lives: -10)
      #
      # @param [ Hash ] increments The field/inc increment pairs.
      #
      # @return [ Document ] The document.
      #
      # @since 4.0.0
      def inc(increments)
        prepare_atomic_operation do |ops|
          process_atomic_operations(increments) do |field, value|
            increment = value.__to_inc__
            current = attributes[field]
            attributes[field] = (current || 0) + increment
            ops[atomic_attribute_name(field)] = increment
          end
          { "$inc" => ops }
        end
      end
    end
  end
end
