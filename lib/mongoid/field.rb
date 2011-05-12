# encoding: utf-8
module Mongoid #:nodoc:

  # Defines the behaviour for defined fields in the document.
  class Field

    NO_CAST_ON_READ = [
      Array, Binary, Boolean, Float, Hash,
      Integer, BSON::ObjectId, Set, String, Symbol
    ]

    attr_accessor :type
    attr_reader :copyable, :klass, :label, :name, :options

    class << self

      # Return a map of custom option names to their handlers.
      #
      # @example
      #   Mongoid::Field.options
      #   # => { :required => #<Proc:0x00000100976b38> }
      #
      # @return [ Hash ] the option map
      def options
        @options ||= {}
      end

      # Stores the provided block to be run when the option name specified is
      # defined on a field.
      #
      # No assumptions are made about what sort of work the handler might
      # perform, so it will always be called if the `option_name` key is
      # provided in the field definition -- even if it is false or nil.
      #
      # @example
      #   Mongoid::Field.option :required do |model, field, value|
      #     model.validates_presence_of field if value
      #   end
      #
      # @param [ Symbol ] option_name the option name to match against
      # @param [ Proc ] block the handler to execute when the option is
      #   provided.
      def option(option_name, &block)
        options[option_name] = block
      end

    end

    # When reading the field do we need to cast the value? This holds true when
    # times are stored or for big decimals which are stored as strings.
    #
    # @example Typecast on a read?
    #   field.cast_on_read?
    #
    # @return [ true, false ] If the field should be cast.
    def cast_on_read?
      !NO_CAST_ON_READ.include?(type)
    end

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
        type.set(object)
      else
        if object.blank?
          type.set(object) if object.is_a?(Array)
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
