# frozen_string_literal: true

module Mongoid

  # Encapsulates behavior around logging and caching warnings so they are only
  # logged once.
  #
  # @api private
  module Warnings

    class << self
      def warning(id, message)
        singleton_class.class_eval do
          define_method("warn_#{id}") do
            unless instance_variable_get("@#{id}")
              Mongoid.logger.warn(message)
              instance_variable_set("@#{id}", true)
            end
          end
        end
      end
    end

    warning :geo_haystack_deprecated, 'The geoHaystack type is deprecated.'
    warning :as_json_compact_deprecated, '#as_json :compact option is deprecated. Please call #compact on the returned Hash object instead.'
    warning :symbol_type_deprecated, 'The BSON Symbol type is deprecated by MongoDB. Please use String or StringifiedSymbol field types instead of the Symbol field type.'
    warning :legacy_readonly, 'The readonly! method will only mark the document readonly when the legacy_readonly feature flag is switched off.'
    warning :use_activesupport_time_zone_deprecated, 'Config option :use_activesupport_time_zone is deprecated and should be removed from your config. It will always be true beginning in Mongoid 9.0.'
    warning :broken_aggregables_deprecated, 'Config option :broken_aggregables is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :broken_alias_handling_deprecated, 'Config option :broken_alias_handling is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :broken_and_deprecated, 'Config option :broken_and is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :broken_scoping_deprecated, 'Config option :broken_scoping is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :broken_updates_deprecated, 'Config option :broken_updates is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :compare_time_by_ms_deprecated, 'Config option :compare_time_by_ms is deprecated. It will always be true beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :legacy_attributes_deprecated, 'Config option :legacy_attributes is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :legacy_pluck_distinct_deprecated, 'Config option :legacy_pluck_distinct is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :legacy_triple_equals_deprecated, 'Config option :legacy_triple_equals is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :object_id_as_json_oid_deprecated, 'Config option :object_id_as_json_oid is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :overwrite_chained_operators_deprecated, 'Config option :overwrite_chained_operators is deprecated. It will always be false beginning in Mongoid 9.0. Please use load_defaults for Mongoid 8.0 or later, then remove it from your config.'
    warning :mutable_ids, 'In Mongoid 9.0 the _id field will be immutable. In earlier versions of 8.x, mutating the _id field was supported inconsistently. Prepare your code for 9.0 by setting Mongoid::Config.immutable_ids to true.'
    warning :mongoid_query_cache, 'In Mongoid 9.0, Mongoid::QueryCache will be removed. Please replace it with Mongo::QueryCache.'
    warning :mongoid_query_cache_clear, 'In Mongoid 9.0, Mongoid::QueryCache#clear_cache should be replaced it with Mongo::QueryCache#clear.'
  end
end
