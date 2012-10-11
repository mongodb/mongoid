# encoding: utf-8
module Mongoid
  module Extensions
    module Set

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   set.mongoize
      #
      # @return [ Hash ] The object mongoized.
      #
      # @since 3.0.0
      def mongoize
        ::Set.mongoize(self)
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Set.demongoize({ "min" => 1, "max" => 5 })
        #
        # @param [ Hash ] object The object to demongoize.
        #
        # @return [ Set ] The set.
        #
        # @since 3.0.0
        def demongoize(object)
          ::Set.new(object)
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Set.mongoize(1..3)
        #
        # @param [ Set ] object The object to mongoize.
        #
        # @return [ Hash ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          object.to_a
        end
      end
    end
  end
end

::Set.__send__(:include, Mongoid::Extensions::Set)
::Set.__send__(:extend, Mongoid::Extensions::Set::ClassMethods)
