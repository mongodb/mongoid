# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Fields
    # Represents a field that should be encrypted.
    class Encrypted < Standard
      def initialize(name, options = {})
        @encryption_options = if options[:encrypt].is_a?(Hash)
                                options[:encrypt]
                              else
                                {}
                              end
        super
      end

      # @return [ true | false | nil ] Whether the field should be encrypted using a
      #   deterministic encryption algorithm; if not specified, nil is returned.
      def deterministic?
        @encryption_options[:deterministic]
      end

      # @return [ String | nil ] The key id to use for encryption; if not specified,
      #   nil is returned.
      def key_id
        @encryption_options[:key_id]
      end

      # @return [ String | nil ] The name of the field that contains the
      #   key alt name to use for encryption; if not specified, nil is returned.
      def key_name_field
        @encryption_options[:key_name_field]
      end

      # Override the key_id for the field.
      #
      # This method is solely for testing purposes and should not be used in
      # the application code. The schema_map is generated very early in the
      # application lifecycle, and overriding the key_id after that will not
      # have any effect.
      #
      # @api private
      def set_key_id(key_id)
        @encryption_options[:key_id] = key_id
      end
    end
  end
end
