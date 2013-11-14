# encoding: utf-8
module Mongoid
  module Relations

    # This module contains the validating logic for options passed to relation
    # macros.
    module Options
      extend self

      # These options are available to all relations.
      COMMON = [
        :class_name,
        :counter_cache,
        :extend,
        :inverse_class_name,
        :inverse_of,
        :name,
        :relation,
        :validate
      ]

      # Determine if the provided options are valid for the relation.
      #
      # @example Check the options.
      #   Options.validate!(:name => :comments)
      #
      # @param [ Hash ] options The options to check.
      #
      # @raise [ ArgumentError ] If the options are invalid.
      #
      # @return [ true, false ] If the options are valid.
      #
      # @since 2.1.0
      def validate!(options)
        valid_options = options[:relation].valid_options.concat(COMMON)
        options.keys.each do |key|
          if !valid_options.include?(key)
            raise Errors::InvalidOptions.new(
              options[:name],
              key,
              valid_options
            )
          end
        end
        true
      end
    end
  end
end
