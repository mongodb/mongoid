module Mongoid #:nodoc:

  # Defines the behaviour for defined fields in the document.
  class Field

    attr_accessor :type
    attr_reader :copyable, :klass, :label, :name, :options

    # Get the default value for the field.
    #
    # @example Get the default.
    #   field.default
    #
    # @return [ Object ] The typecast default value.
    #
    # @since 1.0.0
    def default
      copy.respond_to?(:call) ? copy : set(copy)
    end

    # Create the new field with a name and optional additional options.
    #
    # @example Create the new field.
    #   Field.new(:name, :type => String)
    #
    # @param [ Hash ] options The field options.
    #
    # @option options [ Class ] :type The class of the field.
    # @option options [ Object ] :default The default value for the field.
    # @option options [ String ] :label The field's label.
    #
    # @since 1.0.0
    def initialize(name, options = {})
      @type = options[:type] || Object
      @name, @default, @label = name, options[:default], options[:label]
      @copyable = (@default.is_a?(Array) || @default.is_a?(Hash))
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
    # @example Get the setter value.
    #   field.set("New Value")
    #
    # @param [ Object ] object The value to cast to a database value.
    #
    # @return [ Object ] The typecast value.
    #
    # @since 1.0.0
    def set(object)
      unless options[:identity]
        defined?(type.set) ? type.set(object) : object
      else
        if object.blank?
          defined?(type.set) ? type.set(object) : object if object.is_a?(Array)
        else
          options[:metadata].constraint.convert(object)
        end
      end
    end

    # Used for retrieving the object out of the attributes hash.
    #
    # @example Get the value.
    #   field.get("Value")
    #
    # @param [ Object ] The object to cast from the database.
    #
    # @return [ Object ] The converted value.
    #
    # @since 1.0.0
    def get(object)
      type.get(object)
    end

    # Helper method that delegates to the data type as to whether or not it
    # requires type casting.
    #
    # @return [ true, false ] True/False depending on whether or not MongoDB
    #   inherently represents the data type (e.g. would return false for Date/BigDecimal)
    #
    # @since 2.0.1
    def needs_type_casting?
      defined?(type.needs_type_casting?) ? type.needs_type_casting? : false
    end

    protected

    # Copy the default value if copyable.
    #
    # @example Copy the default.
    #   field.copy
    #
    # @return [ Object ] The copied object or the original.
    #
    # @since 1.0.0
    def copy
      copyable ? @default.dup : @default
    end

    # Checks if the default value is of the same type as the field.
    #
    # @example Check the default value.
    #   field.check_default!
    #
    # @raise [ Errors::InvalidType ] If the types differ.
    #
    # @since 1.0.0
    def check_default!
      return if @default.is_a?(Proc)
      if !@default.nil? && !@default.is_a?(type)
        raise Mongoid::Errors::InvalidType.new(type, @default)
      end
    end
  end
end
