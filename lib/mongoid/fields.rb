# frozen_string_literal: true

require "mongoid/fields/standard"
require "mongoid/fields/foreign_key"
require "mongoid/fields/localized"
require "mongoid/fields/validators"

module Mongoid

  # This module defines behavior for fields.
  module Fields
    extend ActiveSupport::Concern

    StringifiedSymbol = Mongoid::StringifiedSymbol
    Boolean = Mongoid::Boolean

    # For fields defined with symbols use the correct class.
    TYPE_MAPPINGS = {
      array: Array,
      big_decimal: BigDecimal,
      binary: BSON::Binary,
      boolean: Mongoid::Boolean,
      date: Date,
      date_time: DateTime,
      float: Float,
      hash: Hash,
      integer: Integer,
      object_id: BSON::ObjectId,
      range: Range,
      regexp: Regexp,
      set: Set,
      string: String,
      stringified_symbol: StringifiedSymbol,
      symbol: Symbol,
      time: Time
    }.with_indifferent_access

    # Constant for all names of the _id field in a document.
    #
    # This does not include aliases of _id field.
    #
    # @api private
    IDS = [ :_id, '_id', ].freeze

    # BSON classes that are not supported as field types
    #
    # @api private
    INVALID_BSON_CLASSES = [ BSON::Decimal128, BSON::Int32, BSON::Int64 ].freeze

    module ClassMethods
      # Returns the list of id fields for this model class, as both strings
      # and symbols.
      #
      # @return [ Array<Symbol | String> ] List of id fields.
      #
      # @api private
      def id_fields
        IDS.dup.tap do |id_fields|
          aliased_fields.each do |k, v|
            if v == '_id'
              id_fields << k.to_sym
              id_fields << k
            end
          end
        end
      end

      # Extracts the id field from the specified attributes hash based on
      # aliases defined in this class.
      #
      # @param [ Hash ] attributes The attributes to inspect.
      #
      # @return [ Object ] The id value.
      #
      # @api private
      def extract_id_field(attributes)
        id_fields.each do |k|
          if v = attributes[k]
            return v
          end
        end
        nil
      end

      # Removes the _translations from the given field name. This is done only
      # when there doesn't already exist a field name or relation with the
      # same name (i.e. with the _translations suffix). This check for an
      # existing field is done recursively
      #
      # @param [ String | Symbol ] name The name of the field to cleanse.
      #
      # @return [ Field ] The field name without _translations
      def cleanse_localized_field_names(name)
        name = database_field_name(name.to_s)

        klass = self
        [].tap do |res|
          ar = name.split('.')
          ar.each_with_index do |fn, i|
            key = fn
            unless klass.fields.key?(fn) || klass.relations.key?(fn)
              if tr = fn.match(/(.*)_translations\z/)&.captures&.first
                key = tr
              else
                key = fn
              end

            end
            res.push(key)

            if klass.fields.key?(fn)
              res.push(ar.drop(i+1).join('.')) unless i == ar.length - 1
              break
            elsif klass.relations.key?(fn)
              klass = klass.relations[key].klass
            end
          end
        end.join('.')
      end
    end

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
        default: ->{ BSON::ObjectId.new },
        pre_processed: true,
        type: BSON::ObjectId
      )

      alias_attribute(:id, :_id)
    end

    # Apply all default values to the document which are not procs.
    #
    # @example Apply all the non-proc defaults.
    #   model.apply_pre_processed_defaults
    #
    # @return [ Array<String> ] The names of the non-proc defaults.
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
    # @return [ Array<String> ] The names of the proc defaults.
    def apply_post_processed_defaults
      pending_callbacks.delete(:apply_post_processed_defaults)
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
    def apply_default(name)
      unless attributes.key?(name)
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
    def apply_defaults
      pending_callbacks.delete(:apply_defaults)
      apply_pre_processed_defaults
      apply_post_processed_defaults
    end

    # Returns an array of names for the attributes available on this object.
    #
    # Provides the field names in an ORM-agnostic way. Rails v3.1+ uses this
    # method to automatically wrap params in JSON requests.
    #
    # @example Get the field names
    #   document.attribute_names
    #
    # @return [ Array<String> ] The field names
    def attribute_names
      self.class.attribute_names
    end

    # Get the name of the provided field as it is stored in the database.
    # Used in determining if the field is aliased or not.
    #
    # @example Get the database field name.
    #   model.database_field_name(:authorization)
    #
    # @param [ String | Symbol ] name The name to get.
    #
    # @return [ String ] The name of the field as it's stored in the db.
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
    # @return [ true | false ] If we set the field lazily.
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
    # @return [ true | false ] Using object ids.
    def using_object_ids?
      self.class.using_object_ids?
    end

    # Does this field start with a dollar sign ($) or contain a dot/period (.)?
    #
    # @api private
    #
    # @param [ String ] name The field name.
    #
    # @return [ true | false ] If this field is dotted or dollared.
    def dot_dollar_field?(name)
      n = aliased_fields[name] || name
      fields.key?(n) && (n.include?('.') || n.start_with?('$'))
    end

    # Validate whether or not the field starts with a dollar sign ($) or
    # contains a dot/period (.).
    #
    # @api private
    #
    # @raise [ InvalidDotDollarAssignment ] If contains dots or starts with a dollar.
    #
    # @param [ String ] name The field name.
    def validate_writable_field_name!(name)
      if dot_dollar_field?(name)
        raise Errors::InvalidDotDollarAssignment.new(self.class, name)
      end
    end

    class << self

      # Stores the provided block to be run when the option name specified is
      # defined on a field.
      #
      # No assumptions are made about what functionality the handler might
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
      def options
        @options ||= {}
      end

      # Traverse down the association tree and search for the field for the
      # given key. To do this, split the key by '.' and for each part (meth) of
      # the key:
      #
      # - If the meth is a field, yield the meth, field, and is_field as true.
      # - If the meth is an association, update the klass to the association's
      #   klass, and yield the meth, klass, and is_field as false.
      #
      # The next iteration will use klass's fields and associations to continue
      # traversing the tree.
      #
      # @param [ String ] key The key used to search the association tree.
      # @param [ Hash ] fields The fields to begin the search with.
      # @param [ Hash ] associations The associations to begin the search with.
      # @param [ Hash ] aliased_associations The alaised associations to begin
      #   the search with.
      # @param [ Proc ] block The block takes in three paramaters, the current
      #   meth, the field or the relation, and whether the second parameter is a
      #   field or not.
      #
      # @return [ Field ] The field found for the given key at the end of the
      #   search. This will return nil if the last thing found is an association
      #   or no field was found for the given key.
      #
      # @api private
      def traverse_association_tree(key, fields, associations, aliased_associations)
        klass = nil
        field = nil
        key.split('.').each_with_index do |meth, i|
          fs = i == 0 ? fields : klass&.fields
          rs = i == 0 ? associations : klass&.relations
          as = i == 0 ? aliased_associations : klass&.aliased_associations

          # Associations can possibly have two "keys", their name and their alias.
          # The fields name is what is used to store it in the klass's relations
          # and field hashes, and the alias is what's used to store that field
          # in the database. The key inputted to this function is the aliased
          # key. We can convert them back to their names by looking in the
          # aliased_associations hash.
          aliased = meth
          if as && a = as.fetch(meth, nil)
            aliased = a.to_s
          end

          field = nil
          klass = nil
          if fs && f = fs[aliased]
            field = f
            yield(meth, f, true) if block_given?
          elsif rs && rel = rs[aliased]
            klass = rel.klass
            yield(meth, rel, false) if block_given?
          else
            yield(meth, nil, false) if block_given?
          end
        end
        field
      end

      # Get the name of the provided field as it is stored in the database.
      # Used in determining if the field is aliased or not. Recursively
      # finds aliases for embedded documents and fields, delimited with
      # period "." character.
      #
      # Note that this method returns the name of associations as they're
      # stored in the database, whereas the `relations` hash uses their in-code
      # aliases. In order to check for membership in the relations hash, you
      # would first have to look up the string returned from this method in
      # the aliased_associations hash.
      #
      # This method will not expand the alias of a belongs_to association that
      # is not the last item. For example, if we had a School that has_many
      # Students, and the field name passed was (from the Student's perspective):
      #
      #   school._id
      #
      # The alias for a belongs_to association is that association's _id field.
      # Therefore, expanding out this association would yield:
      #
      #   school_id._id
      #
      # This is not the correct field name, because the intention here was not
      # to get a property of the _id field. The intention was to get a property
      # of the referenced document. Therefore, if a part of the name passed is
      # a belongs_to association that is not the last part of the name, we
      # won't expand its alias, and return:
      #
      #   school._id
      #
      # If the belongs_to association is the last part of the name, we will
      # pass back the _id field.
      #
      # @param [ String | Symbol ] name The name to get.
      # @param [ Hash ] relations The associations.
      # @param [ Hash ] alaiased_fields The aliased fields.
      # @param [ Hash ] alaiased_associations The aliased associations.
      #
      # @return [ String ] The name of the field as stored in the database.
      #
      # @api private
      def database_field_name(name, relations, aliased_fields, aliased_associations)
        if Mongoid.broken_alias_handling
          return nil unless name
          normalized = name.to_s
          aliased_fields[normalized] || normalized
        else
          return nil unless name.present?
          key = name.to_s
          segment, remaining = key.split('.', 2)

          # Don't get the alias for the field when a belongs_to association
          # is not the last item. Therefore, get the alias when one of the
          # following is true:
          # 1. This is the last item, i.e. there is no remaining.
          # 2. It is not an association.
          # 3. It is not a belongs association
          if !remaining || !relations.key?(segment) || !relations[segment].is_a?(Association::Referenced::BelongsTo)
            segment = aliased_fields[segment]&.dup || segment
          end

          return segment unless remaining

          relation = relations[aliased_associations[segment] || segment]
          if relation
            k = relation.klass
            "#{segment}.#{database_field_name(remaining, k.relations, k.aliased_fields, k.aliased_associations)}"
          else
            "#{segment}.#{remaining}"
          end
        end
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
      def attribute_names
        fields.keys
      end

      # Get the name of the provided field as it is stored in the database.
      # Used in determining if the field is aliased or not.
      #
      # @param [ String | Symbol ] name The name to get.
      #
      # @return [ String ] The name of the field as it's stored in the db.
      def database_field_name(name)
        Fields.database_field_name(name, relations, aliased_fields, aliased_associations)
      end

      # Defines all the fields that are accessible on the Document
      # For each field that is defined, a getter and setter will be
      # added as an instance method to the Document.
      #
      # @example Define a field.
      #   field :score, type: Integer, default: 0
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The options to pass to the field.
      #
      # @option options [ Class | Symbol | String ] :type The type of the field.
      # @option options [ String ] :label The label for the field.
      # @option options [ Object | Proc ] :default The field's default.
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
      def replace_field(name, type)
        remove_defaults(name)
        add_field(name, fields[name].options.merge(type: type))
      end

      # Convenience method for determining if we are using +BSON::ObjectIds+ as
      # our id.
      #
      # @example Does this class use object ids?
      #   person.using_object_ids?
      #
      # @return [ true | false ] If the class uses BSON::ObjectIds for the id.
      def using_object_ids?
        fields["_id"].object_id_field?
      end

      # Traverse down the association tree and search for the field for the
      # given key.
      #
      # @param [ String ] key The key used to search the association tree.
      # @param [ Proc ] block The block takes in three paramaters, the current
      #   meth, the field or the relation, and whether the second parameter is a
      #   field or not.
      #
      # @return [ Field ] The field found for the given key at the end of the
      #   search. This will return nil if the last thing found is an association
      #   or no field was found for the given key.
      #
      # @api private
      def traverse_association_tree(key, &block)
        Fields.traverse_association_tree(key, fields, relations, aliased_associations, &block)
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
      # @api private
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
      #
      # @api private
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
      #
      # @api private
      def process_options(field)
        field_options = field.options

        Fields.options.each_pair do |option_name, handler|
          if field_options.key?(option_name)
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
      # @api private
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
      # @api private
      def create_field_getter(name, meth, field)
        generated_methods.module_eval do
          re_define_method(meth) do
            raw = read_raw_attribute(name)
            if lazy_settable?(field, raw)
              write_attribute(name, field.eval_default(self))
            else
              process_raw_attribute(name.to_s, raw, field)
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
      # @api private
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
      # @api private
      def create_field_setter(name, meth, field)
        generated_methods.module_eval do
          re_define_method("#{meth}=") do |value|
            val = write_attribute(name, value)
            if field.foreign_key?
              remove_ivar(field.association.name)
            end
            val
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
      # @api private
      def create_field_check(name, meth)
        generated_methods.module_eval do
          re_define_method("#{meth}?") do
            value = read_raw_attribute(name)
            lookup_attribute_presence(name, value)
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
      # @api private
      def create_translations_getter(name, meth)
        generated_methods.module_eval do
          re_define_method("#{meth}_translations") do
            attributes[name] ||= {}
            attributes[name].with_indifferent_access
          end
          alias_method :"#{meth}_t", :"#{meth}_translations"
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
      # @api private
      def create_translations_setter(name, meth, field)
        generated_methods.module_eval do
          re_define_method("#{meth}_translations=") do |value|
            attribute_will_change!(name)
            value&.transform_values! do |_value|
              field.type.mongoize(_value)
            end
            attributes[name] = value
          end
          alias_method :"#{meth}_t=", :"#{meth}_translations="
        end
      end

      # Include the field methods as a module, so they can be overridden.
      #
      # @example Include the fields.
      #   Person.generated_methods
      #
      # @return [ Module ] The module of generated methods.
      #
      # @api private
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
      # @api private
      def remove_defaults(name)
        pre_processed_defaults.delete_one(name)
        post_processed_defaults.delete_one(name)
      end

      # Create a field for the given name and options.
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Hash ] options The hash of options.
      #
      # @return [ Field ] The created field.
      #
      # @api private
      def field_for(name, options)
        opts = options.merge(klass: self)
        opts[:type] = retrieve_and_validate_type(name, options[:type])
        return Fields::Localized.new(name, opts) if options[:localize]
        return Fields::ForeignKey.new(name, opts) if options[:identity]
        Fields::Standard.new(name, opts)
      end

      # Get the class for the given type.
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Symbol | Class ] type The type of the field.
      #
      # @return [ Class ] The type of the field.
      #
      # @raises [ Mongoid::Errors::InvalidFieldType ] if given an invalid field
      #   type.
      #
      # @api private
      def retrieve_and_validate_type(name, type)
        type_mapping = TYPE_MAPPINGS[type]
        result = type_mapping || unmapped_type(type)
        if !result.is_a?(Class)
          raise Errors::InvalidFieldType.new(self, name, type)
        else
          if INVALID_BSON_CLASSES.include?(result)
            warn_message = "Using #{result} as the field type is not supported. "
            if result == BSON::Decimal128
              warn_message += "In BSON <= 4, the BSON::Decimal128 type will work as expected for both storing and querying, but will return a BigDecimal on query in BSON 5+."
            else
              warn_message += "Saving values of this type to the database will work as expected, however, querying them will return a value of the native Ruby Integer type."
            end
            Mongoid.logger.warn(warn_message)
          end
        end
        result
      end

      # Returns the type of the field if the type was not in the TYPE_MAPPINGS
      # hash.
      #
      # @param [ Symbol | Class ] type The type of the field.
      #
      # @return [ Class ] The type of the field.
      #
      # @api private
      def unmapped_type(type)
        if "Boolean" == type.to_s
          Mongoid::Boolean
        else
          type || Object
        end
      end
    end
  end
end
