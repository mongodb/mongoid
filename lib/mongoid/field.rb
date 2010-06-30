# encoding: utf-8
module Mongoid #:nodoc:
  class Field
    attr_reader :name, :type

    # Determine if the field is able to be accessible via a mass update.
    #
    # Returns:
    #
    # true if accessible, false if not.
    def accessible?
      !!@accessible
    end

    # Get the declared options for this field
    #
    # Returns:
    #
    # a hash of options 
    def options
      @options
    end

    # Get the default value for the field.
    #
    # Returns:
    #
    # The primitive value or a copy of the default.
    def default
      copy
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
      @type = options[:type] || String
      @name, @default = name, options[:default]
      @copyable = (@default.is_a?(Array) || @default.is_a?(Hash))
      @accessible = options.has_key?(:accessible) ? options[:accessible] : true
      @options = options
      check_default!
    end

    # Used for setting an object in the attributes hash. If nil is provided the
    # default will get returned if it exists.
    def set(object)
      type.set(object)
    end

    # Used for retrieving the object out of the attributes hash.
    def get(object)
      type.get(object)
    end

    protected
    # Slightly faster default check.
    def copy
      @copyable ? @default.dup : @default
    end

    # Check if the name is valid.
    def check_name!(name)
      raise Mongoid::Errors::InvalidField.new(name) if Mongoid.destructive_fields.include?(name.to_s)
    end

    def check_default!
      return if @default.is_a?(Proc)
      if !@default.nil? && !@default.is_a?(@type)
        raise Mongoid::Errors::InvalidType.new(@type, @default)
      end
    end
  end
end
