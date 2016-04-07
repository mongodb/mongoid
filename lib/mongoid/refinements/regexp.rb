module Mongoid
  module Refinements

    refine Regexp.singleton_class do

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Regexp.mongoize(/^[abc]/)
      #
      # @param [ Regexp, String ] object The object to mongoize.
      #
      # @return [ Regexp ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        ::Regexp.new(object)
      end
    end
  end
end