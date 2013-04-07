# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $set operations.
    #
    # @since 4.0.0
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
        prepare_atomic_operation do |ops|
          process_atomic_operations(setters) do |field, value|
            send("#{field}=", value)
            ops[atomic_attribute_name(field)] = attributes[field]
          end
          { "$set" => ops }
        end
      end
    end
  end
end
