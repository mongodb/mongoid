# frozen_string_literal: true

module Mongoid
  module Attributes
    # Base accessor for attribute reading and writing.
    # This accessor performs no caching - every read demongoizes the raw value.
    #
    # This class is stateless and uses a singleton pattern to minimize memory
    # overhead when caching is disabled (the default configuration).
    #
    # @api private
    class Accessor
      # Shared singleton instance for non-caching accessor (stateless)
      @instance = new

      class << self
        attr_reader :instance
      end

      # Read an attribute value from a document.
      #
      # @param [ Document ] document The document to read from.
      # @param [ String | Symbol ] field_name The name of the field.
      # @param [ Fields::Standard ] field The field definition.
      #
      # @return [ Object ] The demongoized attribute value.
      def read(document, field_name, field)
        raw = document.send(:read_raw_attribute, field_name)

        # Handle lazy defaults
        if lazy_settable?(document, field, raw)
          document.write_attribute(field_name, field.eval_default(document))
        else
          document.process_raw_attribute(field_name.to_s, raw, field)
        end
      end

      # Invalidate any cached value for the given field.
      # No-op for base accessor.
      #
      # @param [ String | Symbol ] field_name The name of the field.
      def invalidate(field_name)
        # No-op for base accessor
      end

      # Reset all cached values.
      # No-op for base accessor.
      def reset!
        # No-op for base accessor
      end

      private

      # Check if a field should have its default value lazily set.
      #
      # @param [ Document ] document The document.
      # @param [ Fields::Standard ] field The field definition.
      # @param [ Object ] value The current value.
      #
      # @return [ Boolean ] True if the default should be lazily set.
      def lazy_settable?(document, field, value)
        !document.frozen? && value.nil? && field.lazy?
      end
    end
  end
end
