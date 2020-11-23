module Mongoid
  module Matcher

    # @api private
    module BitsAnySet
      include Bits
      extend self

      def array_matches?(value, condition)
        condition.any? do |c|
          value & (1<<c) > 0
        end
      end

      def int_matches?(value, condition)
        value & condition > 0
      end
    end
  end
end
