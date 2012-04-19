# encoding: utf-8
module Mongoid
  module Extensions
    module Object

      def __mongoize_time__
        self
      end

      # Do or do not, there is no try. -- Yoda.
      #
      # @example Do or do not.
      #   object.do_or_do_not(:use, "The Force")
      #
      # @param [ String, Symbol ] name The method name.
      # @param [ Array ] *args The arguments.
      #
      # @return [ Object, nil ] The result of the method call or nil if the
      #   method does not exist.
      #
      # @since 2.0.0.rc.1
      def do_or_do_not(name, *args)
        send(name, *args) if name && respond_to?(name)
      end

      # Get the value for an instance variable or nil if it doesn't exist.
      #
      # @example Get the value for an instance var.
      #   document.ivar("person")
      #
      # @param [ String ] name The name of the variable.
      #
      # @return [ Object, nil ] The value or nil.
      #
      # @since 2.0.0.rc.1
      def ivar(name)
        if instance_variable_defined?("@#{name}")
          return instance_variable_get("@#{name}")
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
      #
      # @since 3.0.0
      def mongoize
        self
      end

      # Remove the instance variable for the provided name.
      #
      # @example Remove the instance variable
      #   document.remove_ivar("person")
      #
      # @param [ String ] name The name of the variable.
      #
      # @return [ true, false ] If the variable was defined.
      #
      # @since 2.1.0
      def remove_ivar(name)
        if instance_variable_defined?("@#{name}")
          return remove_instance_variable("@#{name}")
        else
          false
        end
      end

      # Get the substitutable version of an object.
      #
      # @example Get the substitutable.
      #   object.substitutable
      #
      # @return [ Object ] self.
      #
      # @since 2.0.0
      def substitutable
        self
      end

      # You must unlearn what you have learned. -- Yoda
      #
      # @example You must perform this execution.
      #   object.you_must(:use, "The Force")
      #
      # @param [ String, Symbol ] name The method name.
      # @param [ Array ] *args The arguments.
      #
      # @return [ Object, nil ] The result of the method call or nil if the
      #   method does not exist. Nil if the object is frozen.
      #
      # @since 2.2.1
      def you_must(name, *args)
        frozen? ? nil : do_or_do_not(name, *args)
      end

      module ClassMethods

        # Convert the object from it's mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Object.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ Object ] The object.
        #
        # @since 3.0.0
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
        #
        # @since 3.0.0
        def mongoize(object)
          object.mongoize
        end
      end
    end
  end
end

::Object.__send__(:include, Mongoid::Extensions::Object)
::Object.__send__(:extend, Mongoid::Extensions::Object::ClassMethods)
