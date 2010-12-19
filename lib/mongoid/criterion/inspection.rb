# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Inspection #:nodoc:

      # Get a pretty string representation of the criteria, including the
      # selector, options, matching count and documents for inspection.
      #
      # @example Inspect the criteria.
      #   criteria.inspect
      #
      # @return [ String ] The inspection string.
      def inspect
        "#<Mongoid::Criteria\n" <<
        "  selector: #{selector},\n" <<
        "  options:  #{options},\n" <<
        "  count:    #{count},\n" <<
        "  matching: #{entries}>"
      end
    end
  end
end
