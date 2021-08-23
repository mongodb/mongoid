# frozen_string_literal: true

module Mongoid
  class Criteria
    module Inspectable

      # Get a pretty string representation of the criteria, including the
      # selector, options, matching count and documents for inspection.
      #
      # @example Inspect the criteria.
      #   criteria.inspect
      #
      # @return [ String ] The inspection string.
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
