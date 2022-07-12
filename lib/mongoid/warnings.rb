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
  end
end

