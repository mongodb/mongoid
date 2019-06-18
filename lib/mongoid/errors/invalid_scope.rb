# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when defining a scope of an invalid type.
    class InvalidScope < MongoidError

      # Create the error.
      #
      # @example Create the error.
      #   InvalidScope.new(Band, {})
      #
      # @param [ Class ] klass The model class.
      # @param [ Object ] value The attempted scope value.
      #
      # @since 3.0.0
      def initialize(klass, value)
        super(
          compose_message("invalid_scope", { klass: klass, value: value })
        )
      end
    end
  end
end
