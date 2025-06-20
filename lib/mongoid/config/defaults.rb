# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Config

    # Encapsulates logic for loading defaults.
    module Defaults

      # Load the defaults for the feature flags in the given Mongoid version.
      # Note that this method will load the *new* functionality introduced in
      # the given Mongoid version.
      #
      # @param [ String | Float ] version The version number as X.y.
      #
      # raises [ ArgumentError ] if an invalid version is given.
      def load_defaults(version)
        case version.to_s
        when /^[0-7]\./
          raise ArgumentError, "Version no longer supported: #{version}"
        when "8.0"
          self.legacy_readonly = true

          load_defaults "8.1"
        when "8.1"
          self.immutable_ids = false
          self.legacy_persistence_context_behavior = true
          self.around_callbacks_for_embeds = true
          self.prevent_multiple_calls_of_embedded_callbacks = false

          load_defaults "9.0"
        when "9.0"
          # All flag defaults currently reflect 9.0 behavior.
        else
          raise ArgumentError, "Unknown version: #{version}"
        end
      end
    end
  end
end
