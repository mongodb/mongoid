# encoding: utf-8
module Mongoid
  module Extensions
    module Boolean
      module ClassMethods

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
          evolve(object)
        end
      end
    end
  end
end

::Boolean.__send__(:extend, Mongoid::Extensions::Boolean::ClassMethods)
