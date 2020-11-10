module Mongoid
  module Matcher

    # @see https://docs.mongodb.com/manual/reference/operator/query/type/
    #
    # @api private
    module Type
      module_function def matches?(exists, value, condition)
        case condition
        when 1
          # Double
          Float === value
        else
          raise Errors::InvalidQuery, "Unknown $type argument #{condition}"
        end
      end
    end
  end
end
