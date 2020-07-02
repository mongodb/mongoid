module Mongoid
  module Matcher

    # @api private
    module Ne
      module_function def matches?(exists, value, condition)
        case condition
        when ::Regexp, BSON::Regexp::Raw
          raise Errors::InvalidQuery, "'$ne' operator does not allow Regexp arguments: #{Errors::InvalidQuery.truncate_expr(condition)}"
        end

        !EqImpl.matches?(exists, value, condition, '$ne')
      end
    end
  end
end
