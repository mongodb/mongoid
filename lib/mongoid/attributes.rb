# encoding: utf-8
require "mongoid/attributes/processing"

module Mongoid #:nodoc:

  # This module contains the logic for handling the internal attributes hash,
  # and how to get and set values.
  module Attributes
    include Processing

    # Returns the object type. This corresponds to the name of the class that
    # this document is, which is used in determining the class to
    # instantiate in various cases.
    #
    # @example Get the type.
    #   person._type
    #
    # @return [ String ] The name of the class the document is.
    #
    # @since 1.0.0
    def _type
      @attributes["_type"]
    end

    # Set the type of the document. This should be the name of the class.
    #
    # @example Set the type
    #   person._type = "Person"
    #
    # @param [ String ] new_type The name of the class.
    #
    # @return [ String ] the new type.
    #
    # @since 1.0.0
    def _type=(new_type)
      @attributes["_type"] = new_type
    end

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
      !read_attribute(name).blank?
    end

    # Get the id associated with this object. This will pull the _id value out
    # of the attributes.
    #
    # @example Get the id.
    #   person.id
    #
    # @return [ BSON::ObjectId, String ] The id of the document.
    #
    # @since 1.0.0
    def id
      @attributes["_id"]
    end
    alias :_id :id

    # Set the id of the document to a new one.
    #
    # @example Set the id.
    #   person.id = BSON::ObjectId.new
    #
    # @param [ BSON::ObjectId, String ] new_id The new id.
    #
    # @return [ BSON::ObjectId, String ] The new id.
    #
    # @since 1.0.0
    def id=(new_id)
      @attributes["_id"] = _id_type.set(new_id)
    end
    alias :_id= :id=

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
      access = name.to_s
      value = @attributes[access]
      typed_value = fields.has_key?(access) ? fields[access].get(value) : value
      accessed(access, typed_value)
    end
    alias :[] :read_attribute

    # Remove a value from the +Document+ attributes. If the value does not exist
    # it will fail gracefully.
    #
    # @example Remove the attribute.
    #   person.remove_attribute(:title)
    #
    # @param [ String, Symbol ] name The name of the attribute to remove.
    #
    # @since 1.0.0
    def remove_attribute(name)
      access = name.to_s
      modify(access, @attributes.delete(name.to_s), nil)
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
    def respond_to?(*args)
      (Mongoid.allow_dynamic_fields &&
        @attributes &&
        @attributes.has_key?(args.first.to_s)
      ) || super
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
      access = name.to_s
      modify(access, @attributes[access], typed_value_for(access, value))
    end
    alias :[]= :write_attribute

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
      process(attrs) do |document|
        document.identify if new? && id.blank?
      end
    end
    alias :attributes= :write_attributes

    protected

    # Get the default values for the attributes.
    #
    # @example Get the defaults.
    #   person.default_attributes
    #
    # @return [ Hash ] The default values for each field.
    #
    # @since 1.0.0
    def default_attributes
      default_values = defaults
      default_values.each_pair do |key, val|
        default_values[key] = typed_value_for(key, val.call) if val.respond_to?(:call)
      end
      default_values || {}
    end

    # Used for allowing accessor methods for dynamic attributes.
    #
    # @param [ String, Symbol ] name The name of the method.
    # @param [ Array ] *args The arguments to the method.
    def method_missing(name, *args)
      attr = name.to_s
      return super unless @attributes.has_key?(attr.reader)
      if attr.writer?
        write_attribute(attr.reader, (args.size > 1) ? args : args.first)
      else
        read_attribute(attr.reader)
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
      fields.has_key?(key) ? fields[key].set(value) : value
    end
  end
end
