# frozen_string_literal: true

module Mongoid
  module Extensions
    module Symbol

      # Is the symbol a valid value for a Mongoid id?
      #
      # @example Is the string an id value?
      #   :_id.mongoid_id?
      #
      # @return [ true | false ] If the symbol is :id or :_id.
      def mongoid_id?
        to_s.mongoid_id?
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Symbol.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Symbol | nil ] The object mongoized or nil.
        def mongoize(object)
          object.try(:to_sym)
        end
        alias :demongoize :mongoize
      end
    end
  end
end

::Symbol.__send__(:include, Mongoid::Extensions::Symbol)
::Symbol.extend(Mongoid::Extensions::Symbol::ClassMethods)
