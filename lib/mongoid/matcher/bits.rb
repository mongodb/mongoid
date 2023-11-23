# rubocop:todo all
module Mongoid
  module Matcher

    # Mixin module included in bitwise expression matchers.
    #
    # @api private
    module Bits

      # Returns whether a value satisfies a bitwise expression.
      #
      # @param [ true | false ] exists Not used.
      # @param [ Object ] value The value to check.
      # @param [ Numeric | Array<Numeric> ] condition The expression
      #   predicate as a bitmask or position list.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def matches?(exists, value, condition)
        case value
        when BSON::Binary
          value = value.data.split('').map { |n| '%02x' % n.ord }.join.to_i(16)
        end
        case condition
        when Array
          array_matches?(value, condition)
        when BSON::Binary
          int_cond = condition.data.split('').map { |n| '%02x' % n.ord }.join.to_i(16)
          int_matches?(value, int_cond)
        when Integer
          if condition < 0
            raise Errors::InvalidQuery, "Invalid value for $#{operator_name} argument: negative integers are not allowed: #{condition}"
          end
          int_matches?(value, condition)
        when Float
          if (int_cond = condition.to_i).to_f == condition
            if int_cond < 0
              raise Errors::InvalidQuery, "Invalid value for $#{operator_name} argument: negative numbers are not allowed: #{condition}"
            end
            int_matches?(value, int_cond)
          else
            raise Errors::InvalidQuery, "Invalid type for $#{operator_name} argument: not representable as an integer: #{condition}"
          end
        else
          raise Errors::InvalidQuery, "Invalid type for $#{operator_name} argument: #{condition}"
        end
      end

      # Returns the name of the expression operator.
      #
      # @return [ String ] The operator name.
      #
      # @api private
      module_function def operator_name
        name.sub(/.*::/, '').sub(/\A(.)/) { |l| l.downcase }
      end
    end
  end
end
