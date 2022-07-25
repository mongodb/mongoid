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
        # 8.1, since the default will be the old functionality until the next
        # major version is released. More likely, the recursion will have to go
        # in the other direction (towards earlier versions).

        case version.to_s
        when "7.3"
          # flags introduced in 7.4 - old functionality
          Mongoid.broken_aggregables = true
          Mongoid.broken_alias_handling = true
          Mongoid.broken_and = true
          Mongoid.broken_scoping = true
          Mongoid.broken_updates = true
          Mongoid.compare_time_by_ms = false
          Mongoid.legacy_pluck_distinct = true
          Mongoid.legacy_triple_equals = true
          Mongoid.object_id_as_json_oid = true

          load_defaults "7.4"
        when "7.4"
          # flags introduced in 7.5 - old functionality
          Mongoid.overwrite_chained_operators = true

          load_defaults "7.5"
        when "7.5"
          # flags introduced in 8.0 - old functionality
          Mongoid.legacy_attributes = true
          Mongoid.map_big_decimal_to_decimal128 = false
        when "8.0"
          # All flag defaults currently reflect 8.0 behavior.
        when "8.1"
          # All flag defaults currently reflect 8.1 behavior.
        else
          raise ArgumentError, "Unknown version: #{version.to_s}"
        end
      end
    end
  end
end