# encoding: utf-8
require "mongoid/fields/mappings"
require "mongoid/fields/serializable"
require "mongoid/fields/internal/timekeeping"
require "mongoid/fields/internal/array"
require "mongoid/fields/internal/big_decimal"
require "mongoid/fields/internal/binary"
require "mongoid/fields/internal/boolean"
require "mongoid/fields/internal/date"
require "mongoid/fields/internal/date_time"
require "mongoid/fields/internal/false_class"
require "mongoid/fields/internal/float"
require "mongoid/fields/internal/hash"
require "mongoid/fields/internal/integer"
require "mongoid/fields/internal/bignum"
require "mongoid/fields/internal/fixnum"
require "mongoid/fields/internal/localized"
require "mongoid/fields/internal/nil_class"
require "mongoid/fields/internal/object"
require "mongoid/fields/internal/object_id"
require "mongoid/fields/internal/range"
require "mongoid/fields/internal/set"
require "mongoid/fields/internal/string"
require "mongoid/fields/internal/symbol"
require "mongoid/fields/internal/time"
require "mongoid/fields/internal/time_with_zone"
require "mongoid/fields/internal/true_class"
require "mongoid/fields/internal/foreign_keys/array"
require "mongoid/fields/internal/foreign_keys/object"

module Mongoid #:nodoc

  # This module defines behaviour for fields.
  module Fields
    extend ActiveSupport::Concern

    included do
      class_attribute :aliased_fields
      class_attribute :fields
      class_attribute :non_proc_defaults
      class_attribute :proc_defaults

      self.aliased_fields = {}
      self.fields = {}
      self.non_proc_defaults = []
      self.proc_defaults = []

      field(:_type, :type => String)
      field(:_id, :type => BSON::ObjectId)

      alias :id :_id
      alias :id= :_id=
    end

    # Apply all default values to the document which are not procs.
    #
    # @example Apply all the non-proc defaults.
    #   model.apply_non_proc_defaults
    #
    # @return [ Array<String ] The names of the non-proc defaults.
    #
    # @since 2.4.0
    def apply_non_proc_defaults
      non_proc_defaults.each do |name|
        apply_default(name)
      end
    end

    # Apply all default values to the document which are procs.
    #
    # @example Apply all the proc defaults.
    #   model.apply_proc_defaults
    #
    # @return [ Array<String ] The names of the proc defaults.
    #
    # @since 2.4.0
    def apply_proc_defaults
      proc_defaults.each do |name|
        apply_default(name)
      end
    end

    # Applies a single default value for the given name.
    #
    # @example Apply a single default.
    #   model.apply_default("name")
    #
    # @param [ String ] name The name of the field.
    #
    # @since 2.4.0
    def apply_default(name)
      unless attributes.has_key?(name)
        if field = fields[name]
          default = field.eval_default(self)
          unless default.nil?
            attribute_will_change!(name)
            attributes[name] = default
          end
        end
      end
    end

    # Apply all the defaults at once.
    #
    # @example Apply all the defaults.
    #   model.apply_defaults
    #
    # @since 2.4.0
    def apply_defaults
      apply_non_proc_defaults
      apply_proc_defaults
    end

    # Get a list of all the default fields for the model.
    #
    # @example Get a list of the defaults.
    #   model.defaults
    #
    # @return [ Array<String ] The names of all defaults.
    #
    # @since 2.4.0
    def defaults
      self.class.defaults
    end

    class << self

      # Stores the provided block to be run when the option name specified is
      # defined on a field.
      #
      # No assumptions are made about what sort of work the handler might
      # perform, so it will always be called if the `option_name` key is
      # provided in the field definition -- even if it is false or nil.
      #
      # @example
      #   Mongoid::Fields.option :required do |model, field, value|
      #     model.validates_presence_of field if value
      #   end
      #
      # @param [ Symbol ] option_name the option name to match against
      # @param [ Proc ] block the handler to execute when the option is
      #   provided.
      #
      # @since 2.1.0
      def option(option_name, &block)
        options[option_name] = block
      end

      # Return a map of custom option names to their handlers.
      #
      # @example
      #   Mongoid::Fields.options
      #   # => { :required => #<Proc:0x00000100976b38> }
      #
      # @return [ Hash ] the option map
      #
      # @since 2.1.0
      def options
        @options ||= {}
      end
    end

    module ClassMethods #:nodoc

      # Get a list of all the default fields for the model.
      #
      # @example Get a list of the defaults.
      #   Model.defaults
      #
      # @return [ Array<String ] The names of all defaults.
      #
      # @since 2.4.0
      def defaults
        non_proc_defaults + proc_defaults
      end

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
        named = name.to_s
        check_field_name!(name)
        add_field(named, options).tap do
          descendants.each do |subclass|
            subclass.add_field(named, options)
          end
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
        subclass.fields, subclass.non_proc_defaults, subclass.proc_defaults =
          fields.dup, non_proc_defaults.dup, proc_defaults.dup
      end

      # Is the field with the provided name a BSON::ObjectId?
      #
      # @example Is the field a BSON::ObjectId?
      #   Person.object_id_field?(:name)
      #
      # @param [ String, Symbol ] name The name of the field.
      #
      # @return [ true, false ] If the field is a BSON::ObjectId.
      #
      # @since 2.2.0
      def object_id_field?(name)
        field_name = name.to_s
        field_name = "_id" if field_name == "id"
        field = fields[field_name]
        field ? field.object_id_field? : false
      end

      # Replace a field with a new type.
      #
      # @example Replace the field.
      #   Model.replace_field("_id", String)
      #
      # @param [ String ] name The name of the field.
      # @param [ Class ] type The new type of field.
      #
      # @return [ Serializable ] The new field.
      #
      # @since 2.1.0
      def replace_field(name, type)
        defaults.delete_one(name)
        add_field(name, fields[name].options.merge(:type => type))
      end

      protected

      # Add the defaults to the model. This breaks them up between ones that
      # are procs and ones that are not.
      #
      # @example Add to the defaults.
      #   Model.add_defaults(field)
      #
      # @param [ Field ] field The field to add for.
      #
      # @since 2.4.0
      def add_defaults(field)
        default, name = field.default_val, field.name.to_s
        unless default.nil?
          if field.default_val.is_a?(::Proc)
            proc_defaults.push(name)
          else
            non_proc_defaults.push(name)
          end
        end
      end

      # Define a field attribute for the +Document+.
      #
      # @example Set the field.
      #   Person.add_field(:name, :default => "Test")
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The hash of options.
      def add_field(name, options = {})
        aliased = options[:as]
        aliased_fields[aliased.to_s] = name if aliased
        type = options[:localize] ? Fields::Internal::Localized : options[:type]
        Mappings.for(type, options[:identity]).instantiate(name, options).tap do |field|
          fields[name] = field
          add_defaults(field)
          create_accessors(name, name, options)
          create_accessors(name, aliased, options) if aliased
          process_options(field)
          create_dirty_methods(name, name)
          create_dirty_methods(name, aliased) if aliased
        end
      end

      # Run through all custom options stored in Mongoid::Fields.options and
      # execute the handler if the option is provided.
      #
      # @example
      #   Mongoid::Fields.option :custom do
      #     puts "called"
      #   end
      #
      #   field = Mongoid::Fields.new(:test, :custom => true)
      #   Person.process_options(field)
      #   # => "called"
      #
      # @param [ Field ] field the field to process
      def process_options(field)
        field_options = field.options

        Fields.options.each_pair do |option_name, handler|
          if field_options.has_key?(option_name)
            handler.call(self, field, field_options[option_name])
          end
        end
      end

      # Determine if the field name is allowed, if not raise an error.
      #
      # @example Check the field name.
      #   Model.check_field_name!(:collection)
      #
      # @param [ Symbol ] name The field name.
      #
      # @raise [ Errors::InvalidField ] If the name is not allowed.
      #
      # @since 2.1.8
      def check_field_name!(name)
        if Mongoid.destructive_fields.include?(name)
          raise Errors::InvalidField.new(name)
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
      #
      # @since 2.0.0
      def create_accessors(name, meth, options = {})
        field = fields[name]

        create_field_getter(name, meth, field)
        create_field_setter(name, meth)
        create_field_check(name, meth)

        if options[:localize]
          create_translations_getter(name, meth)
          create_translations_setter(name, meth)
        end
      end

      # Create the getter method for the provided field.
      #
      # @example Create the getter.
      #   Model.create_field_getter("name", "name", field)
      #
      # @param [ String ] name The name of the attribute.
      # @param [ String ] meth The name of the method.
      # @param [ Field ] field The field.
      #
      # @since 2.4.0
      def create_field_getter(name, meth, field)
        generated_methods.module_eval do
          if meth =~ /\W/
            if field.cast_on_read?
              define_method(meth) do
                fields[name].deserialize(read_attribute(name))
              end
            else
              define_method(meth) do
                read_attribute(name).tap do |value|
                  if value.is_a?(Array) || value.is_a?(Hash)
                    attribute_will_change!(name)
                  end
                end
              end
            end
          else
            if field.cast_on_read?
              class_eval <<-EOM
                def #{meth}
                  fields[#{name.inspect}].deserialize(read_attribute(#{name.inspect}))
                end
              EOM
            else
              class_eval <<-EOM
                def #{meth}
                  read_attribute(#{name.inspect}).tap do |value|
                    if value.is_a?(Array) || value.is_a?(Hash)
                      attribute_will_change!(#{name.inspect})
                    end
                  end
                end
              EOM
            end
          end
        end
      end

      # Create the setter method for the provided field.
      #
      # @example Create the setter.
      #   Model.create_field_setter("name", "name")
      #
      # @param [ String ] name The name of the attribute.
      # @param [ String ] meth The name of the method.
      #
      # @since 2.4.0
      def create_field_setter(name, meth)
        generated_methods.module_eval do
          if meth =~ /\W/
            define_method(meth) do |value|
              write_attribute(name, value)
            end
          else
            class_eval <<-EOM
              def #{meth}=(value)
                write_attribute(#{name.inspect}, value)
              end
            EOM
          end
        end
      end

      # Create the check method for the provided field.
      #
      # @example Create the check.
      #   Model.create_field_check("name", "name")
      #
      # @param [ String ] name The name of the attribute.
      # @param [ String ] meth The name of the method.
      #
      # @since 2.4.0
      def create_field_check(name, meth)
        generated_methods.module_eval do
          if meth =~ /\W/
            define_method("#{meth}?") do
              attr = read_attribute(name)
              attr == true || attr.present?
            end
          else
            class_eval <<-EOM
              def #{meth}?
                attr = read_attribute(#{name.inspect})
                attr == true || attr.present?
              end
            EOM
          end
        end
      end

      # Create the translation getter method for the provided field.
      #
      # @example Create the translation getter.
      #   Model.create_translations_getter("name", "name")
      #
      # @param [ String ] name The name of the attribute.
      # @param [ String ] meth The name of the method.
      #
      # @since 2.4.0
      def create_translations_getter(name, meth)
        generated_methods.module_eval do
          if meth =~ /\W/
            define_method("#{meth}_translations") do
              attributes[name]
            end
          else
            class_eval <<-EOM
              def #{meth}_translations
                attributes[#{name.inspect}]
              end
            EOM
          end
        end
      end

      # Create the translation setter method for the provided field.
      #
      # @example Create the translation setter.
      #   Model.create_translations_setter("name", "name")
      #
      # @param [ String ] name The name of the attribute.
      # @param [ String ] meth The name of the method.
      #
      # @since 2.4.0
      def create_translations_setter(name, meth)
        generated_methods.module_eval do
          if meth =~ /\W/
            define_method("#{meth}_translations=") do |value|
              attribute_will_change!(name)
              attributes[name] = value
            end
          else
            class_eval <<-EOM
              def #{meth}_translations=(value)
                attribute_will_change!(#{name.inspect})
                attributes[#{name.inspect}] = value
              end
            EOM
          end
        end
      end

      # Include the field methods as a module, so they can be overridden.
      #
      # @example Include the fields.
      #   Person.generated_methods
      #
      # @return [ Module ] The module of generated methods.
      #
      # @since 2.0.0
      def generated_methods
        @generated_methods ||= begin
          Module.new.tap { |mod| include(mod) }
        end
      end
    end
  end
end
