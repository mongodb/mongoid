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
        when "7.3"
          # flags introduced in 7.4 - old functionality
          self.broken_aggregables = true
          self.broken_alias_handling = true
          self.broken_and = true
          self.broken_scoping = true
          self.broken_updates = true
          self.compare_time_by_ms = false
          self.legacy_pluck_distinct = true
          self.legacy_triple_equals = true
          self.object_id_as_json_oid = true

          load_defaults "7.4"
        when "7.4"
          # flags introduced in 7.5 - old functionality
          self.legacy_attributes = true
          self.overwrite_chained_operators = true

          load_defaults "7.5"
        when "7.5"
          # flags introduced in 8.0 - old functionality
          self.map_big_decimal_to_decimal128 = false
        when "8.0"
          # All flag defaults currently reflect 8.0 behavior.
        when "8.1"
          # flags introduced in 8.1 - new functionality
          self.legacy_readonly = false
        else
          raise ArgumentError, "Unknown version: #{version}"
        end
      end
    end
  end
end