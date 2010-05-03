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
      @name, @default = name, options[:default]
      @copyable = (@default.is_a?(Array) || @default.is_a?(Hash))
      @type = options[:type] || String
      @accessible = options.has_key?(:accessible) ? options[:accessible] : true
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
  end
end
