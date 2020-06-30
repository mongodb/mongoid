module Mongoid
  module Matcher

    # This module is used by $eq and other operators that need to perform
    # the matching that $eq performs (for example, $ne which negates the result
    # of $eq). Unlike $eq this module takes an original operator as an
    # additional argument to +matches?+ to provide the correct exception
    # messages reflecting the operator that was first invoked.
    #
    # @api private
    module EqImpl
      module_function def matches?(exists, value, condition, original_operator)
        case condition
        when Range
          # Since $ne invokes $eq, the exception message needs to handle
          # both operators.
          raise Errors::InvalidQuery, "Range is not supported as an argument to '#{original_operator}'"
=begin
          if value.is_a?(Array)
            value.any? { |elt| condition.include?(elt) }
          else
            condition.include?(value)
          end
=end
        else
          value == condition ||
          value.is_a?(Array) && value.include?(condition)
        end
      end
    end
  end
end
