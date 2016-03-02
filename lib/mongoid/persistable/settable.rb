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
      def set(setters, options = {})
        context = options[:mongo_context] || Context.new(self)
        prepare_atomic_operation(mongo_context: context) do |ops|
          process_atomic_operations(setters) do |field, value|
            field_and_value_hash = hasherizer(field.split('.'), value)
            field = field_and_value_hash.keys.first
            # todo: pass context
            process_attribute(field, field_and_value_hash[field])
            ops[atomic_attribute_name(field)] = attributes[field]
          end
          { "$set" => ops }
        end
      end
    end

    private

    def hasherizer(keys, value)
      return value if keys.empty?
      {}.tap { |hash| hash[keys.shift] = hasherizer(keys, value) }
    end
  end
end
