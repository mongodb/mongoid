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
      #
      # @since 1.0.0
      def inspect
%Q{#<Mongoid::Criteria
  selector: #{selector.inspect}
  options:  #{options.inspect}
  class:    #{klass}
  embedded: #{embedded?}>
}
      end
    end
  end
end
