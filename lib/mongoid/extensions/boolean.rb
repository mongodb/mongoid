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
      # @return [ true | false | nil ] The object mongoized or nil.
      def mongoize(object)
        return if object.nil?
        if object.to_s =~ (/\A(true|t|yes|y|on|1|1.0)\z/i)
          true
        elsif object.to_s =~ (/\A(false|f|no|n|off|0|0.0)\z/i)
          false
        end
      end
      alias :demongoize :mongoize
    end
  end
end
