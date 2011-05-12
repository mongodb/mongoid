# encoding: utf-8
module Mongoid #:nodoc

  # This module defines behaviour for fields.
  module Fields
    extend ActiveSupport::Concern

    included do
      # Set up the class attributes that must be available to all subclasses.
      # These include defaults, fields
      delegate :defaults, :fields, :to => "self.class"

      field(:_type, :type => String)
      field(:_id, :type => BSON::ObjectId)

      alias :id :_id
      alias :id= :_id=
    end

    module ClassMethods #:nodoc

      # Defines all the fields that are accessible on the Document
      # For each field that is defined, a getter and setter will be
      # added as an instance method to the Document.
      #
      # @example Define a field.
      #   field :score, :type => Integer, :default => 0
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The options to pass to the field.
      #
      # @option options [ Class ] :type The type of the field.
      # @option options [ String ] :label The label for the field.
      # @option options [ Object, Proc ] :default The field's default
      #
      # @return [ Field ] The generated field
      def field(name, options = {})
        access = name.to_s
        set_field(access, options)
      end

      # Return the fields for this class.
      #
      # @example Get the fields.
      #   Person.fields
      #
      # @return [ Hash ] The fields for this document.
      #
      # @since 2.0.0.rc.6
      def fields
        @fields ||= {}
      end

      # Set the fields for the class.
      #
      # @example Set the fields.
      #   Person.fields = fields
      #
      # @param [ Hash ] fields The hash of fields to set.
      #
      # @since 2.0.0.rc.6
      def fields=(fields)
        @fields = fields
      end

      # Returns the default values for the fields on the document.
      #
      # @example Get the defaults.
      #   Person.defaults
      #
      # @return [ Hash ] The field defaults.
      def defaults
        fields.inject({}) do |defs, (field_name,field)|
          next(defs) if field.default.nil?
          defs[field_name.to_s] = field.default
          defs
        end
      end

      # When inheriting, we want to copy the fields from the parent class and
      # set the on the child to start, mimicking the behaviour of the old
      # class_inheritable_accessor that was deprecated in Rails edge.
      #
      # @example Inherit from this class.
      #   Person.inherited(Doctor)
      #
      # @param [ Class ] subclass The inheriting class.
      #
      # @since 2.0.0.rc.6
      def inherited(subclass)
        super
        subclass.fields = fields.dup
      end

      protected

      # Define a field attribute for the +Document+.
      #
      # @example Set the field.
      #   Person.set_field(:name, :default => "Test")
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The hash of options.
      def set_field(name, options = {})
        meth = options.delete(:as) || name
        Field.new(name, options).tap do |field|
          fields[name] = field
          create_accessors(name, meth, options)
          add_dirty_methods(name)
          process_options(field)
        end
      end

      # Run through all custom options stored in Mongoid::Field.options and
      # execute the handler if the option is provided.
      #
      # @example
      #   Mongoid::Field.option :custom do
      #     puts "called"
      #   end
      #
      #   field = Mongoid::Field.new(:test, :custom => true)
      #   Person.process_options(field)
      #   # => "called"
      #
      # @param [ Field ] field the field to process
      def process_options(field)
        options = field.options

        Field.options.each do |option_name, handler|
          if options.has_key?(option_name)
            handler.call(self, field, options[option_name])
          end
        end
      end

      # Create the field accessors.
      #
      # @example Generate the accessors.
      #   Person.create_accessors(:name, "name")
      #   person.name #=> returns the field
      #   person.name = "" #=> sets the field
      #   person.name? #=> Is the field present?
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Symbol ] meth The name of the accessor.
      # @param [ Hash ] options The options.
      def create_accessors(name, meth, options = {})
        field = fields[name]
        generated_field_methods.module_eval do
          if field.cast_on_read?
            define_method(meth) do
              field.get(read_attribute(name))
            end
          else
            define_method(meth) do
              read_attribute(name)
            end
          end
          define_method("#{meth}=") do |value|
            write_attribute(name, value)
          end
          define_method("#{meth}?") do
            attr = read_attribute(name)
            (options[:type] == Boolean) ? attr == true : attr.present?
          end
        end
      end

      # Include the field methods as a module, so they can be overridden.
      #
      # @example Include the fields.
      #   Person.generated_field_methods
      def generated_field_methods
        @generated_field_methods ||= begin
          Module.new.tap do |mod|
            include mod
          end
        end
      end
    end
  end
end
