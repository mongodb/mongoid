# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # This module contains criteria behaviour for exclusion of values.
    module Exclusion

      # Used when wanting to set the fields options directly using a hash
      # instead of going through only or without.
      #
      # @example Set the limited fields.
      #   criteria.fields(:field => 1)
      #
      # @param [ Hash ] attributes The field options.
      #
      # @return [ Criteria ] A newly cloned copy.
      #
      # @since 2.0.2
      def fields(attributes = nil)
        clone.tap { |crit| crit.options[:fields] = attributes || {} }
      end

      def only(*args)
        return clone if args.empty?
        super(*args, :_type)
      end
    end
  end
end
