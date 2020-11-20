module Mongoid
  module Matcher

    # @api private
    module BitsAnyClear
      include Bits
      extend self

      def array_matches?(value, condition)
        condition.any? do |c|
          value & (1<<c) == 0
        end
      end

      def int_matches?(value, condition)
        # either all clear or not (all set and all clear)
        (value & condition == 0) || (!(value & condition == condition) && (value & condition > 0))
      end
    end
  end
end
