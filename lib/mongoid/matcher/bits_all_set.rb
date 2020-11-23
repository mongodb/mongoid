module Mongoid
  module Matcher

    # @api private
    module BitsAllSet
      include Bits
      extend self

      def array_matches?(value, condition)
        condition.all? do |c|
          value & (1<<c) > 0
        end
      end

      def int_matches?(value, condition)
        value & condition == condition
      end
    end
  end
end
