# encoding: utf-8
module Mongoid
  module Extensions
    module Float

      def __mongoize_time__
        ::Time.at(self)
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Float.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          object ? (__numeric__(object) rescue 0.0) : object
        end
      end
    end
  end
end

::Float.__send__(:include, Mongoid::Extensions::Float)
::Float.__send__(:extend, Mongoid::Extensions::Float::ClassMethods)
