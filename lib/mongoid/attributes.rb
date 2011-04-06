# encoding: utf-8
require "mongoid/attributes/processing"

module Mongoid #:nodoc:

  # This module contains the logic for handling the internal attributes hash,
  # and how to get and set values.
  module Attributes
    include Processing

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
      accessed(access, value)
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
      modify(access, @attributes.delete(access), nil)
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
    # @param [ Boolean ] guard_protected_attributes False to skip mass assignment protection.
    #
    # @since 1.0.0
    def write_attributes(attrs = nil, guard_protected_attributes = true)
      process(attrs, guard_protected_attributes) do |document|
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
    #
    # @raise [ RuntimeError ] Always
    # @since 2.0.0.rc.8
    def default_attributes
      raise "default_attributes is no longer valid. Plase use: apply_default_attributes."
    end

    # Set any missing default values in the attributes.
    #
    # @example Get the raw attributes after defaults have been applied.
    #   person.apply_default_attributes
    #
    # @return [ Hash ] The raw attributes.
    #
    # @since 2.0.0.rc.8
    def apply_default_attributes
      (@attributes ||= {}).tap do |h|
        defaults.each_pair do |key, val|
          unless h.has_key?(key)
            h[key] = val.respond_to?(:call) ? typed_value_for(key, val.call) : val
          end
        end
      end
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
