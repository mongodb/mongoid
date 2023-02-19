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
          # When doing a comparison with Time objects, compare using millisecond precision
          if Mongoid.compare_time_by_ms
            if value.kind_of?(Time) && condition.kind_of?(Time)
              time_eq?(value, condition)
            elsif value.is_a?(Array) && condition.kind_of?(Time)
              value.map do |v|
                if v.kind_of?(Time)
                  time_rounded_to_millis(v)
                else
                  v
                end
              end.include?(time_rounded_to_millis(condition))
            else
              value == condition ||
              value.is_a?(Array) && value.include?(condition)
            end
          else
            value == condition ||
            value.is_a?(Array) && value.include?(condition)
          end
        end
      end

      # Per https://www.mongodb.com/docs/ruby-driver/current/tutorials/bson-v4/#time-instances,
      # > Times in BSON (and MongoDB) can only have millisecond precision. When Ruby Time instances
      # are serialized to BSON or Extended JSON, the times are floored to the nearest millisecond.
      #
      # > Because of this flooring, applications are strongly recommended to perform all time
      # calculations using integer math, as inexactness of floating point calculations may produce
      # unexpected results.
      #
      # As such, perform a similar operation to what the bson-ruby gem does
      module_function def time_eq?(time_a, time_b)
        time_rounded_to_millis(time_a) == time_rounded_to_millis(time_b)
      end

      module_function def time_rounded_to_millis(time)
        return time._bson_to_i * 1000 + time.usec.divmod(1000).first
      end
    end
  end
end
