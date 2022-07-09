# frozen_string_literal: true

module Mongoid
  module Contextual
    module Queryable

      # @attribute [r] collection The collection to query against.
      # @attribute [r] criteria The criteria for the context.
      # @attribute [r] klass The klass for the criteria.
      attr_reader :collection, :criteria, :klass

      # Is the enumerable of matching documents empty?
      #
      # @example Is the context empty?
      #   context.blank?
      #
      # @return [ true | false ] If the context is empty.
      def blank?
        !exists?
      end
      alias :empty? :blank?
    end
  end
end
