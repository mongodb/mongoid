# encoding: utf-8
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
      #
      # @since 3.0.0
      def mongoize(object)
        ::Boolean.evolve(object)
      end
      alias :evolve :mongoize
    end
  end
end
