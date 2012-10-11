# encoding: utf-8
require "mongoid/attributes/processing"
require "mongoid/attributes/readonly"

module Mongoid

  # This module contains the logic for handling the internal attributes hash,
  # and how to get and set values.
  module Attributes
    extend ActiveSupport::Concern
    include Processing
    include Readonly

    attr_reader :attributes
    attr_reader :attributes_before_type_cast
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
      attribute = read_attribute(name)
      !attribute.blank? || attribute == false
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
      attributes.has_key?(name.to_s)
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
      attributes_before_type_cast.has_key?(name.to_s)
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
      attributes[name.to_s]
    end
    alias :[] :read_attribute

    # Read a value from the attributes before type cast. If the value has not
    # yet been assigned then this will return the attribute's existing value
    # using read_attribute.
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
      if attributes_before_type_cast.has_key?(attr)
        attributes_before_type_cast[attr]
      else
        read_attribute(attr)
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
      access = name.to_s
      unless attribute_writable?(name)
        raise Errors::ReadonlyAttribute.new(name, :nil)
      end
      _assigning do
        attribute_will_change!(access)
        delayed_atomic_unsets[atomic_attribute_name(access)] = []
        attributes.delete(access)
      end
    end

    # Override respond_to? so it responds properly for dynamic attributes.
    #
    # @example Does this object respond to the method?
    #   person.respond_to?(:title)
    #
    # @param [ Array ] *args The name of the method.
    #
    # @return [ true, false ] True if it does, false if not.
    #
    # @since 1.0.0
    def respond_to?(name, include_private = false)
      super || (
        Mongoid.allow_dynamic_fields &&
        attributes &&
        attributes.has_key?(name.to_s.reader)
      )
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
      access = database_field_name(name.to_s)
      if attribute_writable?(access)
        _assigning do
          localized = fields[access].try(:localized?)
          attributes_before_type_cast[name.to_s] = value
          typed_value = typed_value_for(access, value)
          unless attributes[access] == typed_value || attribute_changed?(access)
            attribute_will_change!(access)
          end
          if localized
            (attributes[access] ||= {}).merge!(typed_value)
          else
            attributes[access] = typed_value
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
    # @param [ Hash ] options Supported options: :without_protection, :as
    #
    # @since 2.2.1
    def assign_attributes(attrs = nil, options = {})
      _assigning do
        process_attributes(attrs, options[:as] || :default, !options[:without_protection])
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
    # @param [ Boolean ] guard_protected_attributes False to skip mass assignment protection.
    #
    # @since 1.0.0
    def write_attributes(attrs = nil, guard_protected_attributes = true)
      assign_attributes(attrs, without_protection: !guard_protected_attributes)
    end
    alias :attributes= :write_attributes

    private

    # Define a reader method for a dynamic attribute.
    #
    # @api private
    #
    # @example Define a reader method.
    #   model.define_dynamic_reader(:field)
    #
    # @param [ String ] name The name of the field.
    #
    # @since 3.0.0
    def define_dynamic_reader(name)
      class_eval <<-READER
        def #{name}
          read_attribute(#{name.inspect})
        end
      READER
    end

    # Define a reader method for a dynamic attribute before type cast.
    #
    # @api private
    #
    # @example Define a reader method for an attribute.
    #   model.define_dynamic_before_type_cast_reader(:field)
    #
    # @param [ String ] name The name of the field.
    #
    # @since 3.1.0
    def define_dynamic_before_type_cast_reader(name)
      class_eval <<-READER
        def #{name}_before_type_cast
          read_attribute_before_type_cast(#{name.inspect})
        end
      READER
    end

    # Define a writer method for a dynamic attribute.
    #
    # @api private
    #
    # @example Define a writer method.
    #   model.define_dynamic_writer(:field)
    #
    # @param [ String ] name The name of the field.
    #
    # @since 3.0.0
    def define_dynamic_writer(name)
      class_eval <<-WRITER
        def #{name}=(value)
          write_attribute(#{name.inspect}, value)
        end
      WRITER
    end

    # Used for allowing accessor methods for dynamic attributes.
    #
    # @param [ String, Symbol ] name The name of the method.
    # @param [ Array ] *args The arguments to the method.
    def method_missing(name, *args)
      attr = name.to_s
      return super unless attributes.has_key?(attr.reader)
      if attr.writer?
        getter = attr.reader
        define_dynamic_writer(getter)
        write_attribute(getter, args.first)
      elsif attr.before_type_cast?
        define_dynamic_before_type_cast_reader(attr.reader)
        read_attribute_before_type_cast(attr.reader)
      else
        getter = attr.reader
        define_dynamic_reader(getter)
        read_attribute(getter)
      end
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
      fields.has_key?(key) ? fields[key].mongoize(value) : value
    end

    module ClassMethods

      # Alias the provided name to the original field. This will provide an
      # aliased getter, setter, existance check, and all dirty attribute
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
        class_eval <<-RUBY
          alias #{name}  #{original}
          alias #{name}= #{original}=
          alias #{name}? #{original}?
          alias #{name}_change   #{original}_change
          alias #{name}_changed? #{original}_changed?
          alias reset_#{name}!   reset_#{original}!
          alias #{name}_was      #{original}_was
          alias #{name}_will_change! #{original}_will_change!
          alias #{name}_before_type_cast #{original}_before_type_cast
        RUBY
      end
    end
  end
end
