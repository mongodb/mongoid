# encoding: utf-8
module Mongoid
  module Extensions
    module DateTime

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   DateTime.mongoize("2012-1-1")
        #
        # @return [ String ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
        end
      end
    end
  end
end

::DateTime.__send__(:include, Mongoid::Extensions::DateTime)
::DateTime.__send__(:extend, Mongoid::Extensions::DateTime::ClassMethods)
