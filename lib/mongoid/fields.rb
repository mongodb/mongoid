# encoding: utf-8
require "mongoid/fields/standard"
require "mongoid/fields/foreign_key"
require "mongoid/fields/localized"
require "mongoid/fields/validators"

module Mongoid

  # This module defines behaviour for fields.
  module Fields
    extend ActiveSupport::Concern

    included do
      class_attribute :aliased_fields
      class_attribute :localized_fields
      class_attribute :fields
      class_attribute :pre_processed_defaults
      class_attribute :post_processed_defaults

      self.aliased_fields = { "id" => "_id" }
      self.fields = {}
      self.localized_fields = {}
      self.pre_processed_defaults = []
      self.post_processed_defaults = []

      field(
        :_id,
        default: ->{ Moped::BSON::ObjectId.new },
        pre_processed: true,
        type: Moped::BSON::ObjectId
      )

      alias :id :_id
      alias :id= :_id=

      attr_protected(:id, :_id, :_type) if Mongoid.protect_sensitive_fields?
    end

    # Apply all default values to the document which are not procs.
    #
    # @example Apply all the non-proc defaults.
    #   model.apply_pre_processed_defaults
    #
    # @return [ Array<String ] The names of the non-proc defaults.
    #
    # @since 2.4.0
    def apply_pre_processed_defaults
      pre_processed_defaults.each do |name|
        apply_default(name)
      end
    end

    # Apply all default values to the document which are procs.
    #
    # @example Apply all the proc defaults.
    #   model.apply_post_processed_defaults
    #
    # @return [ Array<String ] The names of the proc defaults.
    #
    # @since 2.4.0
    def apply_post_processed_defaults
      post_processed_defaults.each do |name|
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
          unless default.nil? || field.lazy?
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
      apply_pre_processed_defaults
      apply_post_processed_defaults
    end

    # Returns an array of names for the attributes available on this object.
    #
    # Provides the field names in an ORM-agnostic way. Rails v3.1+ uses this
    # method to automatically wrap params in JSON requests.
    #
    # @example Get the field names
    #   docment.attribute_names
    #
    # @return [ Array<String> ] The field names
    #
    # @since 3.0.0
    def attribute_names
      self.class.attribute_names
    end

    # Get the name of the provided field as it is stored in the database.
    # Used in determining if the field is aliased or not.
    #
    # @example Get the database field name.
    #   model.database_field_name(:authorization)
    #
    # @param [ String, Symbol ] name The name to get.
    #
    # @return [ String ] The name of the field as it's stored in the db.
    #
    # @since 3.0.7
    def database_field_name(name)
      self.class.database_field_name(name)
    end

    # Is the provided field a lazy evaluation?
    #
    # @example If the field is lazy settable.
    #   doc.lazy_settable?(field, nil)
    #
    # @param [ Field ] field The field.
    # @param [ Object ] value The current value.
    #
    # @return [ true, false ] If we set the field lazily.
    #
    # @since 3.1.0
    def lazy_settable?(field, value)
      !frozen? && value.nil? && field.lazy?
    end

    # Is the document using object ids?
    #
    # @note Refactored from using delegate for class load performance.
    #
    # @example Is the document using object ids?
    #   model.using_object_ids?
    #
    # @return [ true, false ] Using object ids.
    def using_object_ids?
      self.class.using_object_ids?
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

    module ClassMethods

      # Returns an array of names for the attributes available on this object.
      #
      # Provides the field names in an ORM-agnostic way. Rails v3.1+ uses this
      # method to automatically wrap params in JSON requests.
      #
      # @example Get the field names
      #   Model.attribute_names
      #
      # @return [ Array<String> ] The field names
      #
      # @since 3.0.0
      def attribute_names
        fields.keys
      end

      # Get the name of the provided field as it is stored in the database.
      # Used in determining if the field is aliased or not.
      #
      # @example Get the database field name.
      #   Model.database_field_name(:authorization)
      #
      # @param [ String, Symbol ] name The name to get.
      #
      # @return [ String ] The name of the field as it's stored in the db.
      #
      # @since 3.0.7
      def database_field_name(name)
        return nil unless name
        normalized = name.to_s
        aliased_fields[normalized] || normalized
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
        Validators::Macro.validate(self, name, options)
        added = add_field(named, options)
        descendants.each do |subclass|
          subclass.add_field(named, options)
        end
        added
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
        remove_defaults(name)
        add_field(name, fields[name].options.merge(type: type))
      end

      # Convenience method for determining if we are using +Moped::BSON::ObjectIds+ as
      # our id.
      #
      # @example Does this class use object ids?
      #   person.using_object_ids?
      #
      # @return [ true, false ] If the class uses Moped::BSON::ObjectIds for the id.
      #
      # @since 1.0.0
      def using_object_ids?
        fields["_id"].object_id_field?
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
        remove_defaults(name)
        unless default.nil?
          if field.pre_processed?
            pre_processed_defaults.push(name)
          else
            post_processed_defaults.push(name)
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
        field = field_for(name, options)
        fields[name] = field
        add_defaults(field)
        create_accessors(name, name, options)
        create_accessors(name, aliased, options) if aliased
        process_options(field)
        create_dirty_methods(name, name)
        create_dirty_methods(name, aliased) if aliased
        field
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

      # Create the field accessors.
      #
      # @example Generate the accessors.
      #   Person.create_accessors(:name, "name")
      #   person.name #=> returns the field
      #   person.name = "" #=> sets the field
      #   person.name? #=> Is the field present?
      #   person.name_before_type_cast #=> returns the field before type cast
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Symbol ] meth The name of the accessor.
      # @param [ Hash ] options The options.
      #
      # @since 2.0.0
      def create_accessors(name, meth, options = {})
        field = fields[name]

        create_field_getter(name, meth, field)
        create_field_getter_before_type_cast(name, meth)
        create_field_setter(name, meth, field)
        create_field_check(name, meth)

        if options[:localize]
          create_translations_getter(name, meth)
          create_translations_setter(name, meth, field)
          localized_fields[name] = field
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
          re_define_method(meth) do
            raw = read_attribute(name)
            if lazy_settable?(field, raw)
              write_attribute(name, field.eval_default(self))
            else
              value = field.demongoize(raw)
              attribute_will_change!(name) if value.resizable?
              value
            end
          end
        end
      end

      # Create the getter_before_type_cast method for the provided field. If
      # the attribute has been assigned, return the attribute before it was
      # type cast. Otherwise, delegate to the getter.
      #
      # @example Create the getter_before_type_cast.
      #   Model.create_field_getter_before_type_cast("name", "name")
      #
      # @param [ String ] name The name of the attribute.
      # @param [ String ] meth The name of the method.
      #
      # @since 3.1.0
      def create_field_getter_before_type_cast(name, meth)
        generated_methods.module_eval do
          re_define_method("#{meth}_before_type_cast") do
            if has_attribute_before_type_cast?(name)
              read_attribute_before_type_cast(name)
            else
              send meth
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
      # @param [ Field ] field The field.
      #
      # @since 2.4.0
      def create_field_setter(name, meth, field)
        generated_methods.module_eval do
          re_define_method("#{meth}=") do |value|
            write_attribute(name, value)
            if field.foreign_key?
              remove_ivar(field.metadata.name)
            end
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
          re_define_method("#{meth}?") do
            attr = read_attribute(name)
            attr == true || attr.present?
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
          re_define_method("#{meth}_translations") do
            attributes[name] ||= {}
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
      # @param [ Field ] field The field.
      #
      # @since 2.4.0
      def create_translations_setter(name, meth, field)
        generated_methods.module_eval do
          re_define_method("#{meth}_translations=") do |value|
            attribute_will_change!(name)
            if value
              value.update_values do |_value|
                field.type.mongoize(_value)
              end
            end
            attributes[name] = value
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
          mod = Module.new
          include(mod)
          mod
        end
      end

      # Remove the default keys for the provided name.
      #
      # @example Remove the default keys.
      #   Model.remove_defaults(name)
      #
      # @param [ String ] name The field name.
      #
      # @since 2.4.0
      def remove_defaults(name)
        pre_processed_defaults.delete_one(name)
        post_processed_defaults.delete_one(name)
      end

      def field_for(name, options)
        opts = options.merge(klass: self)
        return Fields::Localized.new(name, opts) if options[:localize]
        return Fields::ForeignKey.new(name, opts) if options[:identity]
        Fields::Standard.new(name, opts)
      end
    end
  end
end
