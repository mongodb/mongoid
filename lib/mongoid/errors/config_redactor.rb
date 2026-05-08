# frozen_string_literal: true

module Mongoid
  module Errors
    # Redacts credentials from a client configuration hash before it is
    # interpolated into an exception message.
    module ConfigRedactor
      extend self

      REDACTED = '[REDACTED]'

      # Top-level keys whose values should be replaced wholesale.
      SENSITIVE_KEYS = %w[password auto_encryption_options].freeze

      # Match the userinfo portion of a MongoDB connection string.
      URI_USERINFO = %r{\A(mongodb(?:\+srv)?://)[^@/]+@}.freeze

      # Return a copy of the given config hash with sensitive values redacted.
      # Recurses into nested hashes so that, e.g., `:options =>
      # { :auto_encryption_options => ... }` is also covered. Non-hash inputs
      # are returned unchanged.
      def redact(config)
        return config unless config.is_a?(Hash)

        config.each_with_object({}) do |(key, value), result|
          result[key] = redact_value(key, value)
        end
      end

      def redact_value(key, value)
        if SENSITIVE_KEYS.include?(key.to_s)
          REDACTED
        elsif key.to_s == 'uri' && value.is_a?(String)
          value.sub(URI_USERINFO, "\\1#{REDACTED}@")
        elsif value.is_a?(Hash)
          redact(value)
        else
          value
        end
      end
    end
  end
end
