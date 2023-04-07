# frozen_string_literal: true

module Mongoid
  module Config

    # Encapsulates logic for loading defaults.
    module Defaults

      # Load the defaults for the feature flags in the given Mongoid version.
      # Note that this method will load the *new* functionality introduced in
      # the given Mongoid version.
      #
      # @param [ String | Float ] The version number as X.y.
      #
      # raises [ ArgumentError ] if an invalid version is given.
      def load_defaults(version)
        # Note that for 7.x, since all of the feature flag defaults have been
        # flipped to the new functionality, all of the settings for those
        # versions are to give old functionality. Because of this, it is
        # possible to recurse to later version to get all of the options to
        # turn off. Note that this won't be true when adding feature flags to
        # 9.x, since the default will be the old functionality until the next
        # major version is released. More likely, the recursion will have to go
        # in the other direction (towards earlier versions).

        case version.to_s
        when "7.3", "7.4", "7.5"
          raise ArgumentError, "Version no longer supported: #{version}"
        when "8.0"
          self.legacy_readonly = true

          load_defaults "8.1"
        when "8.1"
          self.immutable_ids = false

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
