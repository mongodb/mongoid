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
      # @return [ Document ] The document.
      #
      # @since 4.0.0
      def set(setters)
        prepare_atomic_operation do |ops|
          process_atomic_operations(setters) do |field, value|
            process_attribute(field.to_s, value)
            unless relations.include?(field.to_s)
              ops[atomic_attribute_name(field)] = attributes[field]
            end
          end
          { "$set" => ops } unless ops.empty?
        end
      end
    end

    def hasherizer(keys, value)
      return value if keys.empty?
      {}.tap { |hash| hash[keys.shift] = hasherizer(keys, value) }
    end
  end
end
