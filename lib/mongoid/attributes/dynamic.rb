# encoding: utf-8
module Mongoid
  module Attributes

    # This module contains the behavior for dynamic attributes.
    module Dynamic
      extend ActiveSupport::Concern

      included do
        class_attribute :allows_dynamic_fields
        self.allows_dynamic_fields = true
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
          attributes &&
          attributes.has_key?(name.to_s.reader)
        )
      end

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

      # If the attribute is dynamic, add a field for it with a type of object
      # and set the value.
      #
      # @example Process the attribute.
      #   document.process_attribute(name, value)
      #
      # @param [ Symbol ] name The name of the field.
      # @param [ Object ] value The value of the field.
      #
      # @since 2.0.0.rc.7
      def process_attribute(name, value)
        responds = respond_to?("#{name}=")
        if !responds
          write_attribute(name, value)
        else
          send("#{name}=", value)
        end
      end

      # Get an array of inspected dynamic fields for the document.
      #
      # @example Inspect the dynamic fields.
      #   document.inspect_dynamic_fields
      #
      # @return [ String ] An array of pretty printed dynamic field values.
      def inspect_dynamic_fields
        keys = @attributes.keys - fields.keys - relations.keys - ["_id", "_type"]
        return keys.map do |name|
          "#{name}: #{@attributes[name].inspect}"
        end
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
        else
          getter = attr.reader
          define_dynamic_reader(getter)
          read_attribute(getter)
        end
      end
    end
  end
end
