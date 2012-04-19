# encoding: utf-8
module Mongoid
  module Extensions
    module Range

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   range.mongoize
      #
      # @return [ Hash ] The object mongoized.
      #
      # @since 3.0.0
      def mongoize
        ::Range.mongoize(self)
      end

      module ClassMethods

        # Convert the object from it's mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Range.demongoize({ "min" => 1, "max" => 5 })
        #
        # @param [ Hash ] object The object to demongoize.
        #
        # @return [ Range ] The range.
        #
        # @since 3.0.0
        def demongoize(object)
          object.nil? ? nil : ::Range.new(object["min"], object["max"])
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Range.mongoize(1..3)
        #
        # @param [ Range ] object The object to mongoize.
        #
        # @return [ Hash ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          object.nil? ? nil : { "min" => object.first, "max" => object.last }
        end
      end
    end
  end
end

::Range.__send__(:include, Mongoid::Extensions::Range)
::Range.__send__(:extend, Mongoid::Extensions::Range::ClassMethods)
