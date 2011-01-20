# encoding: utf-8
module Mongoid #:nodoc:
  class Field
    attr_reader :copyable, :klass, :label, :name, :options, :type

    # Get the default value for the field.
    #
    # Returns:
    #
    # The typecast default value.
    def default
      copy.respond_to?(:call) ? copy : set(copy)
    end

    # Create the new field with a name and optional additional options. Valid
    # options are :default
    #
    # Options:
    #
    # name: The name of the field as a +Symbol+.
    # options: A +Hash+ of options for the field.
    #
    # Example:
    #
    # <tt>Field.new(:score, :default => 0)</tt>
    def initialize(name, options = {})
      check_name!(name)
      @type = options[:type] || Object
      @name, @default = name, options[:default]
      @copyable = (@default.is_a?(Array) || @default.is_a?(Hash))
      @label = options[:label]
      @options = options
      check_default!
    end

    # Used for setting an object in the attributes hash.
    #
    # If nil is provided the default will get returned if it exists.
    #
    # If the field is an identity field, ie an id, it performs the necessary
    # cast.
    #
    # Example:
    #
    # <tt>field.set("New Value")</tt>
    #
    # Returns:
    #
    # The new value.
    def set(object)
      unless options[:identity]
        type.set(object)
      else
        if object.blank?
          type.set(object)
        else
          options[:metadata].constraint.convert(object)
        end
      end
    end

    # Used for retrieving the object out of the attributes hash.
    #
    # Example:
    #
    # <tt>field.get("Value")</tt>
    #
    # Returns:
    #
    # The converted value.
    def get(object)
      type.get(object)
    end

    protected
    # Slightly faster default check.
    def copy
      copyable ? @default.dup : @default
    end

    # Check if the name is valid.
    def check_name!(name)
      if Mongoid.destructive_fields.include?(name.to_s)
        raise Mongoid::Errors::InvalidField.new(name)
      end
    end

    def check_default!
      return if @default.is_a?(Proc)
      if !@default.nil? && !@default.is_a?(type)
        raise Mongoid::Errors::InvalidType.new(type, @default)
      end
    end
  end
end
