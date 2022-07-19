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

    warning :id_sort_deprecated, 'The :id_sort option has been deprecated. Use Mongo#take to get a document without a sort on _id.'
    warning :criteria_cache_deprecated, 'The criteria cache has been deprecated and will be removed in Mongoid 8. Please enable the Mongoid QueryCache to have caching functionality.'
    warning :map_field_deprecated, 'The field argument to the Mongo#map method has been deprecated, please pass in a block instead. Support will be dropped in Mongoid 8.'
  end
end

