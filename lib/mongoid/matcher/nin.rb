# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $nin expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/nin/
    #
    # @api private
    module Nin

      # Returns whether a value satisfies a $nin expression.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Array<Object> ] condition The $nin condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        !In.matches?(exists, value, condition)
      end
    end
  end
end
