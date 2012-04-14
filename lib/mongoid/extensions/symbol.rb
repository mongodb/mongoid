# encoding: utf-8
module Mongoid
  module Extensions
    module Symbol

      REVERSALS = {
        asc: :desc,
        ascending: :descending,
        desc: :asc,
        descending: :ascending
      }

      # Get the inverted sorting option.
      #
      # @example Get the inverted option.
      #   :asc.invert
      #
      # @return [ String ] The string inverted.
      def invert
        REVERSALS[self]
      end

      # Is the symbol a valid value for a Mongoid id?
      #
      # @example Is the string an id value?
      #   :_id.mongoid_id?
      #
      # @return [ true, false ] If the symbol is :id or :_id.
      #
      # @since 2.3.1
      def mongoid_id?
        to_s =~ /^(|_)id$/
      end
    end
  end
end

::Symbol.__send__(:include, Mongoid::Extensions::Symbol)
