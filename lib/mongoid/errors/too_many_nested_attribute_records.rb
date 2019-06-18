# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when trying to create set nested records above the
    # specified :limit
    #
    # @example Create the error.
    #   TooManyNestedAttributeRecords.new('association', limit)
    class TooManyNestedAttributeRecords < MongoidError
      def initialize(association, limit)
        super(
          compose_message(
            "too_many_nested_attribute_records",
            { association: association, limit: limit }
          )
        )
      end
    end
  end
end
