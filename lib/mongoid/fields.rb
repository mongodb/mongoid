# encoding: utf-8
module Mongoid #:nodoc
  module Fields #:nodoc
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        # Set up the class attributes that must be available to all subclasses.
        # These include defaults, fields
        class_inheritable_accessor :defaults, :fields

        self.defaults = {}.with_indifferent_access
        self.fields = {}.with_indifferent_access

        delegate :defaults, :fields, :to => "self.class"
      end
    end

    module ClassMethods #:nodoc
      # Defines all the fields that are accessable on the Document
      # For each field that is defined, a getter and setter will be
      # added as an instance method to the Document.
      #
      # Options:
      #
      # name: The name of the field, as a +Symbol+.
      # options: A +Hash+ of options to supply to the +Field+.
      #
      # Example:
      #
      # <tt>field :score, :default => 0</tt>
      def field(name, options = {})
        set_field(name, options)
        set_default(name, options)
      end

      protected
      # Define a field attribute for the +Document+.
      def set_field(name, options = {})
        meth = options.delete(:as) || name
        fields[name] = Field.new(name.to_s, options)
        create_accessors(name, meth, options)
      end

      # Create the field accessors.
      def create_accessors(name, meth, options = {})
        define_method(meth) { read_attribute(name) }
        define_method("#{meth}=") { |value| write_attribute(name, value) }
        define_method("#{meth}?") { read_attribute(name) == true } if options[:type] == Boolean
      end

      # Set up a default value for a field.
      def set_default(name, options = {})
        value = options[:default]
        defaults[name] = value if value
      end
    end
  end
end
