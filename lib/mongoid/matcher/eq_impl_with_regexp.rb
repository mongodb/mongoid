module Mongoid
  module Matcher

    # This is an internal equality implementation that performs exact
    # comparisons and regular expression matches.
    #
    # @api private
    module EqImplWithRegexp
      module_function def matches?(original_operator, value, condition)
        case condition
        when Regexp
          value =~ condition
        when ::BSON::Regexp::Raw
          value =~ condition.compile
        else
          value == condition
        end
      end
    end
  end
end
