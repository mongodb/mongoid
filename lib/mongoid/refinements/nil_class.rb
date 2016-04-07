module Mongoid
  module Refinements

    refine NilClass do

      # Try to form a setter from this object.
      #
      # @example Try to form a setter.
      #   object.setter
      #
      # @return [ nil ] Always nil.
      #
      # @since 6.0.0
      def setter; self; end

      # Get the name of a nil collection.
      #
      # @example Get the nil name.
      #   nil.collectionize
      #
      # @return [ String ] A blank string.
      #
      # @since 6.0.0
      def collectionize
        to_s.collectionize
      end
    end
  end
end