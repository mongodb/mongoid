# frozen_string_literal: true

module Mongoid
  class Boolean

    class << self

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Boolean.mongoize("123.11")
      #
      # @return [ String ] The object mongoized.
      def mongoize(object)
        wrap_mongoize(object) do
          if object.to_s =~ (/\A(true|t|yes|y|on|1|1.0)\z/i)
            true
          elsif object.to_s =~ (/\A(false|f|no|n|off|0|0.0)\z/i)
            false
          end
        end
      end
    end
  end
end
