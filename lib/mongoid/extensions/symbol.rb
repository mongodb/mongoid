# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Extensions

    # Adds type-casting behavior to Symbol class.
    module Symbol

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
