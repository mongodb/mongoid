# frozen_string_literal: true

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
    end
  end
end
