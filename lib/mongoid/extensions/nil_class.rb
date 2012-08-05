# encoding: utf-8
module Mongoid
  module Extensions
    module NilClass

      # Try to form a setter from this object.
      #
      # @example Try to form a setter.
      #   object.__setter__
      #
      # @return [ nil ] Always nil.
      #
      # @since 3.1.0
      def __setter__
        self
      end

      # Get the name of a nil collection.
      #
      # @example Get the nil name.
      #   nil.collectionize
      #
      # @return [ String ] A blank string.
      #
      # @since 1.0.0
      def collectionize
        to_s.collectionize
      end
    end
  end
end

::NilClass.__send__(:include, Mongoid::Extensions::NilClass)
