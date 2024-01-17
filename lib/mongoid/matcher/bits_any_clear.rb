# rubocop:todo all
module Mongoid
  module Matcher

    # In-memory matcher for $bitsAnyClear expression.
    #
    # @see https://www.mongodb.com/docs/manual/reference/operator/query/bitsAnyClear/
    #
    # @api private
    module BitsAnyClear
      include Bits
      extend self

      # Returns whether a position list condition matches a value.
      #
      # @param [ Object ] value The value to check.
      # @param [ Array<Numeric> ] condition The position list condition.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def array_matches?(value, condition)
        condition.any? do |c|
          value & (1<<c) == 0
        end
      end

      # Returns whether a bitmask condition matches a value.
      #
      # @param [ Object ] value The value to check.
      # @param [ Numeric ] condition The bitmask condition.
      #
      # @return [ true | false ] Whether the value matches.
      #
      # @api private
      def int_matches?(value, condition)
        value & condition < condition
      end
    end
  end
end
