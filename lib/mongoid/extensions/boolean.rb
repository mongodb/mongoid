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
      def evolve(object)
        ::Boolean.evolve(object)
      end
      alias :mongoize :evolve

    end
  end
end
