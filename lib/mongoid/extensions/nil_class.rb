# encoding: utf-8
module Mongoid
  module Extensions
    module NilClass

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
