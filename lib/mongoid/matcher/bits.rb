module Mongoid
  module Matcher

    # @api private
    module Bits
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

      module_function def operator_name
        name.sub(/.*::/, '').sub(/\A(.)/) { |l| l.downcase }
      end
    end
  end
end
