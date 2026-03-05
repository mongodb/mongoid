# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Contextual
    module Aggregable

      # @api private
      EMPTY_RESULT = {
        "count" => 0,
        "sum" => 0,
        "avg" => nil,
        "min" => nil,
        "max" => nil,
      }.freeze
    end
  end
end
