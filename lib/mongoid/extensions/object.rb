# frozen_string_literal: true

module Mongoid
  module Extensions
    module Object

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
      def __find_args__
        self
      end

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

      # Try to form a setter from this object.
      #
      # @example Try to form a setter.
      #   object.__setter__
      #
      # @return [ String ] The object as a string plus =.
      def __setter__
        "#{self}="
      end

      # Get the value of the object as a mongo friendly sort value.
      #
      # @example Get the object as sort criteria.
      #   object.__sortable__
      #
      # @return [ Object ] self.
      def __sortable__
        self
      end

      # Conversion of an object to an $inc-able value.
      #
      # @example Convert the object.
      #   1.__to_inc__
      #
      # @return [ Object ] The object.
      def __to_inc__
        self
      end

      # Checks whether conditions given in this object are known to be
      # unsatisfiable, i.e., querying with this object will always return no
      # documents.
      #
      # This method is deprecated. Mongoid now uses
      # +_mongoid_unsatisfiable_criteria?+ internally; this method is retained
      # for backwards compatibility only. It always returns false.
      #
      # @return [ false ] Always false.
      # @deprecated
      def blank_criteria?
        false
      end

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
      def do_or_do_not(name, *args)
        send(name, *args) if name && respond_to?(name)
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

      # Is the object multi args.
      #
      # @example Is the object multi args?
      #   object.multi_arged?
      #
      # @return [ false ] false.
      def multi_arged?
        false
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
      def you_must(name, *args)
        frozen? ? nil : do_or_do_not(name, *args)
      end

      module ClassMethods

        # Convert the provided object to a foreign key, given the metadata key
        # contstraint.
        #
        # @example Convert the object to a fk.
        #   Object.__mongoize_fk__(association, object)
        #
        # @param [ Association ] association The association metadata.
        # @param [ Object ] object The object to convert.
        #
        # @return [ Object ] The converted object.
        def __mongoize_fk__(association, object)
          return nil if !object || object == ""
          association.convert_to_foreign_key(object)
        end

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

::Object.__send__(:include, Mongoid::Extensions::Object)
::Object.extend(Mongoid::Extensions::Object::ClassMethods)

::Mongoid.deprecate(Object, :blank_criteria)
