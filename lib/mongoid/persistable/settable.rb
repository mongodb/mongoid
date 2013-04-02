# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $set operations.
    #
    # @since 2.0.0
    module Settable
      extend ActiveSupport::Concern

      # Perform a $set operation on the provided field/value pairs and set the
      # values in the document in memory.
      #
      # @example Set the values.
      #   document.set(title: "sir", dob: Date.new(1970, 1, 1))
      #
      # @param [ Hash ] setters The field/value pairs to set.
      #
      # @return [ true ] If the operation succeeded.
      #
      # @since 4.0.0
      def set(setters)
        prepare_atomic_operation do |coll, selector, ops|
          setters.each do |field, value|
            normalized = database_field_name(field)
            send("#{field}=", value)
            changed_attributes.delete(normalized)
            ops[atomic_attribute_name(normalized)] = attributes[normalized]
          end
          coll.find(selector).update(positionally(selector, "$set" => ops))
        end
      end
    end
  end
end
