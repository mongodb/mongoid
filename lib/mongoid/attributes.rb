# frozen_string_literal: true
# encoding: utf-8

require "active_model/attribute_methods"
require "mongoid/attributes/dynamic"
require "mongoid/attributes/nested"
require "mongoid/attributes/processing"
require "mongoid/attributes/readonly"

module Mongoid

  # This module contains the logic for handling the internal attributes hash,
  # and how to get and set values.
  module Attributes
    extend ActiveSupport::Concern
    include Nested
    include Processing
    include Readonly

    attr_reader :attributes
    alias :raw_attributes :attributes

    # Determine if an attribute is present.
    #
    # @example Is the attribute present?
    #   person.attribute_present?("title")
    #
    # @param [ String, Symbol ] name The name of the attribute.
    #
    # @return [ true, false ] True if present, false if not.
    #
    # @since 1.0.0
    def attribute_present?(name)
      attribute = read_raw_attribute(name)
      !attribute.blank? || attribute == false
    rescue ActiveModel::MissingAttributeError
      false
    end

    # Get the attributes that have not been cast.
    #
    # @example Get the attributes before type cast.
    #   document.attributes_before_type_cast
    #
    # @return [ Hash ] The uncast attributes.
    #
    # @since 3.1.0
    def attributes_before_type_cast
      @attributes_before_type_cast ||= {}
    end

    # Does the document have the provided attribute?
    #
    # @example Does the document have the attribute?
    #   model.has_attribute?(:name)
    #
    # @param [ String, Symbol ] name The name of the attribute.
    #
    # @return [ true, false ] If the key is present in the attributes.
    #
    # @since 3.0.0
    def has_attribute?(name)
      attributes.key?(name.to_s)
    end

    # Does the document have the provided attribute before it was assigned
    # and type cast?
    #
    # @example Does the document have the attribute before it was assigned?
    #   model.has_attribute_before_type_cast?(:name)
    #
    # @param [ String, Symbol ] name The name of the attribute.
    #
    # @return [ true, false ] If the key is present in the
    #   attributes_before_type_cast.
    #
    # @since 3.1.0
    def has_attribute_before_type_cast?(name)
      attributes_before_type_cast.key?(name.to_s)
    end

    # Read a value from the document attributes. If the value does not exist
    # it will return nil.
    #
    # @example Read an attribute.
    #   person.read_attribute(:title)
    #
    # @example Read an attribute (alternate syntax.)
    #   person[:title]
    #
    # @param [ String, Symbol ] name The name of the attribute to get.
    #
    # @return [ Object ] The value of the attribute.
    #
    # @since 1.0.0
    def read_attribute(name)
      field = fields[name.to_s]
      raw = read_raw_attribute(name)
      field ? field.demongoize(raw) : raw
    end
    alias :[] :read_attribute

    # Read a value from the attributes before type cast. If the value has not
    # yet been assigned then this will return the attribute's existing value
    # using read_raw_attribute.
    #
    # @example Read an attribute before type cast.
    #   person.read_attribute_before_type_cast(:price)
    #
    # @param [ String, Symbol ] name The name of the attribute to get.
    #
    # @return [ Object ] The value of the attribute before type cast, if
    #   available. Otherwise, the value of the attribute.
    #
    # @since 3.1.0
    def read_attribute_before_type_cast(name)
      attr = name.to_s
      if attributes_before_type_cast.key?(attr)
        attributes_before_type_cast[attr]
      else
        read_raw_attribute(attr)
      end
    end

    # Remove a value from the +Document+ attributes. If the value does not exist
    # it will fail gracefully.
    #
    # @example Remove the attribute.
    #   person.remove_attribute(:title)
    #
    # @param [ String, Symbol ] name The name of the attribute to remove.
    #
    # @raise [ Errors::ReadonlyAttribute ] If the field cannot be removed due
    #   to being flagged as reaodnly.
    #
    # @since 1.0.0
    def remove_attribute(name)
      as_writable_attribute!(name) do |access|
        _assigning do
          attribute_will_change!(access)
          delayed_atomic_unsets[atomic_attribute_name(access)] = [] unless new_record?
          attributes.delete(access)
        end
      end
    end

    # Write a single attribute to the document attribute hash. This will
    # also fire the before and after update callbacks, and perform any
    # necessary typecasting.
    #
    # @example Write the attribute.
    #   person.write_attribute(:title, "Mr.")
    #
    # @example Write the attribute (alternate syntax.)
    #   person[:title] = "Mr."
    #
    # @param [ String, Symbol ] name The name of the attribute to update.
    # @param [ Object ] value The value to set for the attribute.
    #
    # @since 1.0.0
    def write_attribute(name, value)
      field_name = database_field_name(name)
      if attribute_writable?(field_name)
        _assigning do
          validate_attribute_value(field_name, value)
          localized = fields[field_name].try(:localized?)
          attributes_before_type_cast[name.to_s] = value
          typed_value = typed_value_for(field_name, value)
          unless attributes[field_name] == typed_value || attribute_changed?(field_name)
            attribute_will_change!(field_name)
          end
          if localized
            attributes[field_name] ||= {}
            attributes[field_name].merge!(typed_value)
          else
            attributes[field_name] = typed_value
          end
          typed_value
        end
      end
    end
    alias :[]= :write_attribute

    # Allows you to set all the attributes for a particular mass-assignment security role
    # by passing in a hash of attributes with keys matching the attribute names
    # (which again matches the column names)  and the role name using the :as option.
    # To bypass mass-assignment security you can use the :without_protection => true option.
    #
    # @example Assign the attributes.
    #   person.assign_attributes(:title => "Mr.")
    #
    # @example Assign the attributes (with a role).
    #   person.assign_attributes({ :title => "Mr." }, :as => :admin)
    #
    # @param [ Hash ] attrs The new attributes to set.
    #
    # @since 2.2.1
    def assign_attributes(attrs = nil)
      _assigning do
        process_attributes(attrs)
      end
    end

    # Writes the supplied attributes hash to the document. This will only
    # overwrite existing attributes if they are present in the new +Hash+, all
    # others will be preserved.
    #
    # @example Write the attributes.
    #   person.write_attributes(:title => "Mr.")
    #
    # @example Write the attributes (alternate syntax.)
    #   person.attributes = { :title => "Mr." }
    #
    # @param [ Hash ] attrs The new attributes to set.
    #
    # @since 1.0.0
    def write_attributes(attrs = nil)
      assign_attributes(attrs)
    end
    alias :attributes= :write_attributes

    # Determine if the attribute is missing from the document, due to loading
    # it from the database with missing fields.
    #
    # @example Is the attribute missing?
    #   document.attribute_missing?("test")
    #
    # @param [ String ] name The name of the attribute.
    #
    # @return [ true, false ] If the attribute is missing.
    #
    # @since 4.0.0
    def attribute_missing?(name)
      selection = __selected_fields
      return false unless selection
      field = fields[name]
      (selection.values.first == 0 && selection_excluded?(name, selection, field)) ||
        (selection.values.first == 1 && !selection_included?(name, selection, field))
    end

    # Return type-casted attributes.
    #
    # @example Type-casted attributes.
    #   document.typed_attributes
    #
    # @return [ Object ] The hash with keys and values of the type-casted attributes.
    #
    # @since 6.1.0
    def typed_attributes
      attribute_names.map { |name| [name, send(name)] }.to_h
    end

    private

    def selection_excluded?(name, selection, field)
      selection[name] == 0
    end

    def selection_included?(name, selection, field)
      selection.key?(name) || selection.keys.collect { |k| k.partition('.').first }.include?(name)
    end

    # Does the string contain dot syntax for accessing hashes?
    #
    # @api private
    #
    # @example Is the string in dot syntax.
    #   model.hash_dot_syntax?
    #
    # @return [ true, false ] If the string contains a "."
    #
    # @since 3.0.15
    def hash_dot_syntax?(string)
      string.include?(".")
    end

    # Return the typecasted value for a field.
    #
    # @example Get the value typecasted.
    #   person.typed_value_for(:title, :sir)
    #
    # @param [ String, Symbol ] key The field name.
    # @param [ Object ] value The uncast value.
    #
    # @return [ Object ] The cast value.
    #
    # @since 1.0.0
    def typed_value_for(key, value)
      fields.key?(key) ? fields[key].mongoize(value) : value.mongoize
    end

    private

    def read_raw_attribute(name)
      normalized = database_field_name(name.to_s)
      if attribute_missing?(normalized)
        raise ActiveModel::MissingAttributeError, "Missing attribute: '#{name}'."
      end
      if hash_dot_syntax?(normalized)
        attributes.__nested__(normalized)
      else
        attributes[normalized]
      end
    end

    module ClassMethods

      # Alias the provided name to the original field. This will provide an
      # aliased getter, setter, existence check, and all dirty attribute
      # methods.
      #
      # @example Alias the attribute.
      #   class Product
      #     include Mongoid::Document
      #     field :price, :type => Float
      #     alias_attribute :cost, :price
      #   end
      #
      # @param [ Symbol ] name The new name.
      # @param [ Symbol ] original The original name.
      #
      # @since 2.3.0
      def alias_attribute(name, original)
        aliased_fields[name.to_s] = original.to_s

        alias_method name, original
        alias_method "#{name}=", "#{original}="
        alias_method "#{name}?", "#{original}?"
        alias_method "#{name}_change", "#{original}_change"
        alias_method "#{name}_changed?", "#{original}_changed?"
        alias_method "reset_#{name}!", "reset_#{original}!"
        alias_method "reset_#{name}_to_default!", "reset_#{original}_to_default!"
        alias_method "#{name}_was", "#{original}_was"
        alias_method "#{name}_will_change!", "#{original}_will_change!"
        alias_method "#{name}_before_type_cast", "#{original}_before_type_cast"
      end
    end

    private

    # Validates an attribute value as being assignable to the specified field.
    #
    # For now, only Hash and Array fields are validated, and the value is
    # being checked to be of an appropriate type (i.e. either Hash or Array,
    # respectively, or nil).
    #
    # This method takes the name of the field as stored in the document
    # in the database, not (necessarily) the Ruby method name used to read/write
    # the said field.
    #
    # @param [ String, Symbol ] field_name The name of the field.
    # @param [ Object ] value The value to be validated.
    #
    # @since 3.0.10
    def validate_attribute_value(field_name, value)
      return if value.nil?
      field = fields[field_name]
      return unless field
      validatable_types = [ Hash, Array ]
      if validatable_types.include?(field.type)
        unless value.is_a?(field.type)
          raise Mongoid::Errors::InvalidValue.new(field.type, value.class)
        end
      end
    end

    def lookup_attribute_presence(name, value)
      if localized_fields.has_key?(name) && value
        value = localized_fields[name].send(:lookup, value)
      end
      value.present?
    end
  end
end
