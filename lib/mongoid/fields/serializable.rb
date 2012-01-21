# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:

    # Defines the behaviour for defined fields in the document.
    #
    # For people who want to have custom field types in their
    # applications and want control over the serialization process
    # to and from the domain model and MongoDB you will need to include
    # this module in your custom type class. You will also need to define
    # either a #serialize and #deserialize instance method, where previously
    # these were a .set and .get class method respectively.
    #
    #   class MyCustomType
    #     include Mongoid::Fields::Serializable
    #
    #     def deserialize(object)
    #       # Do something to convert it from Mongo to my type.
    #     end
    #
    #     def serialize(object)
    #       # Do something to convert from my type to MongoDB friendly.
    #     end
    #   end
    module Serializable
      extend ActiveSupport::Concern

      included do
        class_attribute :cast_on_read
      end

      # Set readers for the instance variables.
      attr_accessor :default_val, :label, :localize, :name, :options

      def normalized_name
        name.to_sym
      end

      # Get the constraint from the metadata once.
      #
      # @example Get the constraint.
      #   field.constraint
      #
      # @return [ Constraint ] The relation's contraint.
      #
      # @since 2.1.0
      def constraint
        @constraint ||= metadata.constraint
      end

      # Deserialize this field from the type stored in MongoDB to the type
      # defined on the model
      #
      # @example Deserialize the field.
      #   field.deserialize(object)
      #
      # @param [ Object ] object The object to cast.
      #
      # @return [ Object ] The converted object.
      #
      # @since 2.1.0
      def deserialize(object); object; end

      # Evaluate the default value and return it. Will handle the
      # serialization, proc calls, and duplication if necessary.
      #
      # @example Evaluate the default value.
      #   field.eval_default(document)
      #
      # @param [ Document ] doc The document the field belongs to.
      #
      # @return [ Object ] The serialized default value.
      #
      # @since 2.1.8
      def eval_default(doc)
        if default_val.respond_to?(:call)
          serialize(doc.instance_exec(&default_val))
        else
          serialize(default_val.duplicable? ? default_val.dup : default_val)
        end
      end

      # Is this field a foreign key?
      #
      # @example Is the field a foreign key?
      #   field.foreign_key?
      #
      # @return [ true, false ] If the field is a foreign key.
      #
      # @since 2.4.0
      def foreign_key?
        !!options[:identity]
      end

      # Is the field localized or not?
      #
      # @example Is the field localized?
      #   field.localized?
      #
      # @return [ true, false ] If the field is localized.
      #
      # @since 2.3.0
      def localized?
        !!@localize
      end

      # Get the metadata for the field if its a foreign key.
      #
      # @example Get the metadata.
      #   field.metadata
      #
      # @return [ Metadata ] The relation metadata.
      #
      # @since 2.2.0
      def metadata
        @metadata ||= options[:metadata]
      end

      # Is the field a BSON::ObjectId?
      #
      # @example Is the field a BSON::ObjectId?
      #   field.object_id_field?
      #
      # @return [ true, false ] If the field is a BSON::ObjectId.
      #
      # @since 2.2.0
      def object_id_field?
        @object_id_field ||= (type == BSON::ObjectId)
      end

      # Does the field pre-process it's default value?
      #
      # @example Does the field pre-process the default?
      #   field.pre_processed?
      #
      # @return [ true, false ] If the field's default is pre-processed.
      #
      # @since 3.0.0
      def pre_processed?
        @pre_processed ||=
          (options[:pre_processed] || (default_val && !default_val.is_a?(::Proc)))
      end

      # Can the field vary in size, similar to arrays.
      #
      # @example Is the field varying in size?
      #   field.resizable?
      #
      # @return [ false ] false by default.
      #
      # @since 2.4.0
      def resizable?; false; end

      # Serialize the object from the type defined in the model to a MongoDB
      # compatible object to store.
      #
      # @example Serialize the field.
      #   field.serialize(object)
      #
      # @param [ Object ] object The object to cast.
      #
      # @return [ Object ] The converted object.
      #
      # @since 2.1.0
      def serialize(object); object; end

      # Convert the provided object to a Mongoid criteria friendly value.
      #
      # @example Convert the field.
      #   field.selection(object)
      #
      # @param [ Object ] The object to convert.
      #
      # @return [ Object ] The converted object.
      #
      # @since 2.4.0
      def selection(object); object; end

      # Get the type of this field - inferred from the class name.
      #
      # @example Get the type.
      #   field.type
      #
      # @return [ Class ] The name of the class.
      #
      # @since 2.1.0
      def type
        @type ||= options[:type] || Object
      end

      # Is this field included in versioned attributes?
      #
      # @example Is the field versioned?
      #   field.versioned?
      #
      # @return [ true, false ] If the field is included in versioning.
      #
      # @since 2.1.0
      def versioned?
        @versioned ||= (options[:versioned].nil? ? true : options[:versioned])
      end

      module ClassMethods #:nodoc:

        # Create the new field with a name and optional additional options.
        #
        # @example Create the new field.
        #   Field.new(:name, :type => String)
        #
        # @param [ Hash ] options The field options.
        #
        # @option options [ Class ] :type The class of the field.
        # @option options [ Object ] :default The default value for the field.
        # @option options [ String ] :label The field's label.
        #
        # @since 2.1.0
        def instantiate(name, options = {})
          allocate.tap do |field|
            field.name = name
            field.options = options
            field.label = options[:label]
            field.localize = options[:localize]
            field.default_val = options[:default]
          end
        end

        private

        # If we define a method called deserialize then we need to cast on
        # read.
        #
        # @example Hook into method added.
        #   method_added(:deserialize)
        #
        # @param [ Symbol ] method The method name.
        #
        # @since 2.3.4
        def method_added(method)
          self.cast_on_read = true if method == :deserialize
        end
      end
    end
  end
end
