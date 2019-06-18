# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when trying to access a Mongo::Collection from an
    # embedded document.
    #
    # @example Create the error.
    #   InvalidCollection.new(Address)
    class InvalidCollection < MongoidError
      def initialize(klass)
        super(
          compose_message("invalid_collection", { klass: klass.name })
        )
      end
    end
  end
end
