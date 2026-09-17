module Mongoid
  module Matcher

    # This is an internal equality implementation that performs exact
    # comparisons and regular expression matches.
    #
    # @api private
    module EqImplWithRegexp
      module_function def matches?(_original_operator, value, condition)
        case condition
        when Regexp, ::BSON::Regexp::Raw
          value.respond_to?(:=~) && RegexpBudget.match?(value, condition)
        else
          if Mongoid.compare_time_by_ms &&
            value.kind_of?(Time) && condition.kind_of?(Time)
            EqImpl.time_eq?(value, condition)
          else
            value == condition
          end
        end
      end
    end
  end
end
