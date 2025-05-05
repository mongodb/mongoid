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

      # Convert the object to args for a find query.
      #
      # @example Convert the object to args.
      #   object.__find_args__
      #
      # @return [ Object ] self.
      # @deprecated
      def __find_args__
        self
      end
      Mongoid.deprecate(self, :__find_args__)

      # Try to form a setter from this object.
      #
      # @example Try to form a setter.
      #   object.__setter__
      #
      # @return [ String ] The object as a string plus =.
      # @deprecated
      def __setter__
        "#{self}="
      end
      Mongoid.deprecate(self, :__setter__)

      # Get the value of the object as a mongo friendly sort value.
      #
      # @example Get the object as sort criteria.
      #   object.__sortable__
      #
      # @return [ Object ] self.
      # @deprecated
      def __sortable__
        self
      end
      Mongoid.deprecate(self, :__sortable__)

      # Conversion of an object to an $inc-able value.
      #
      # @example Convert the object.
      #   1.__to_inc__
      #
      # @return [ Object ] The object.
      # @deprecated
      def __to_inc__
        self
      end
      Mongoid.deprecate(self, :__to_inc__)


      # Do or do not, there is no try. -- Yoda.
      #
      # @example Do or do not.
      #   object.do_or_do_not(:use, "The Force")
      #
      # @param [ String | Symbol ] name The method name.
      # @param [ Object... ] *args The arguments.
      #
      # @return [ Object | nil ] The result of the method call or nil if the
      #   method does not exist.
      # @deprecated
      def do_or_do_not(name, *args)
        send(name, *args) if name && respond_to?(name)
      end
      Mongoid.deprecate(self, :do_or_do_not)

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

      # Is the object multi args.
      #
      # @example Is the object multi args?
      #   object.multi_arged?
      #
      # @return [ false ] false.
      # @deprecated
      def multi_arged?
        false
      end
      Mongoid.deprecate(self, :multi_arged?)

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

      # You must unlearn what you have learned. -- Yoda
      #
      # @example You must perform this execution.
      #   object.you_must(:use, "The Force")
      #
      # @param [ String | Symbol ] name The method name.
      # @param [ Object... ] *args The arguments.
      #
      # @return [ Object | nil ] The result of the method call or nil if the
      #   method does not exist. Nil if the object is frozen.
      # @deprecated
      def you_must(name, *args)
        frozen? ? nil : do_or_do_not(name, *args)
      end
      Mongoid.deprecate(self, :you_must)

      module ClassMethods
        # Convert the provided object to a foreign key, given the metadata key
        # contstraint.
        #
        # @example Convert the object to a fk.
        #   Object.__mongoize_fk__(association, object)
        #
        # @param [ Mongoid::Association::Relatable ] association The association metadata.
        # @param [ Object ] object The object to convert.
        #
        # @return [ Object ] The converted object.
        # @deprecated
        def __mongoize_fk__(association, object)
          return nil if !object || object == ""
          association.convert_to_foreign_key(object)
        end
        Mongoid.deprecate(self, :__mongoize_fk__)

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
