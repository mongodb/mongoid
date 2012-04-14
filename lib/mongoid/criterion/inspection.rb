# encoding: utf-8
module Mongoid
  module Criterion
    module Inspection

      # Get a pretty string representation of the criteria, including the
      # selector, options, matching count and documents for inspection.
      #
      # @example Inspect the criteria.
      #   criteria.inspect
      #
      # @return [ String ] The inspection string.
      def inspect
        "#<Mongoid::Criteria\n" <<
        "  selector: #{selector.inspect},\n" <<
        "  options:  #{options.inspect},\n" <<
        "  class:    #{klass},\n" <<
        "  embedded: #{embedded}>\n"
      end
    end
  end
end
