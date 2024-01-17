# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $eq expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/eq/
    #
    # @api private
    module Eq

      # Returns whether a value satisfies an $eq expression.
      #
      # @param [ true | false ] exists Whether the value exists.
      # @param [ Object ] value The value to check.
      # @param [ Hash ] expr The $eq condition predicate.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      module_function def matches?(exists, value, condition)
        EqImpl.matches?(exists, value, condition, '$eq')
      end
    end
  end
end
