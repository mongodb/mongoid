# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Extensions
    # Adds type-casting behavior to Object class.
    module Object
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Evolve a plain object into an object id.
      #
      # @example Evolve the object.
      #   object.__evolve_object_id__
      #
      # @return [ Object ] self.
      def __evolve_object_id__
        self
      end
      alias :__mongoize_object_id__ :__evolve_object_id__

      # Mongoize a plain object into a time.
      #
      # @note This method should not be used, because it does not
      #   return correct results for non-Time objects. Override
      #   __mongoize_time__ in classes that are time-like to return an
      #   instance of Time or ActiveSupport::TimeWithZone.
      #
      # @example Mongoize the object.
      #   object.__mongoize_time__
      #
      # @return [ Object ] self.
      # @deprecated
      def __mongoize_time__
        self
      end

      # Get the value for an instance variable or false if it doesn't exist.
      #
      # @example Get the value for an instance var.
      #   document.ivar("person")
      #
      # @param [ String ] name The name of the variable.
      #
      # @return [ Object | false ] The value or false.
      def ivar(name)
        var_name = "@_#{name}"
        if instance_variable_defined?(var_name)
          return instance_variable_get(var_name)
        else
          false
        end
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Object ] The object.
      def mongoize
        self
      end

      # Is the object a number?
      #
      # @example Is the object a number?.
      #   object.numeric?
      #
      # @return [ false ] Always false.
      def numeric?
        false
      end

      # Remove the instance variable for the provided name.
      #
      # @example Remove the instance variable
      #   document.remove_ivar("person")
      #
      # @param [ String ] name The name of the variable.
      #
      # @return [ true | false ] If the variable was defined.
      def remove_ivar(name)
        if instance_variable_defined?("@_#{name}")
          return remove_instance_variable("@_#{name}")
        else
          false
        end
      end

      # Is the object's size changable? Only returns true for arrays and hashes
      # currently.
      #
      # @example Is the object resizable?
      #   object.resizable?
      #
      # @return [ false ] false.
      def resizable?
        false
      end

      # Get the substitutable version of an object.
      #
      # @example Get the substitutable.
      #   object.substitutable
      #
      # @return [ Object ] self.
      def substitutable
        self
      end

      module ClassMethods
        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Object.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ Object ] The object.
        def demongoize(object)
          object
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Object.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Object ] The object mongoized.
        def mongoize(object)
          object.mongoize
        end
      end
    end
  end
end

Object.include Mongoid::Extensions::Object
