# encoding: utf-8
module Mongoid #:nodoc
  module Fields #:nodoc
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        # Set up the class attributes that must be available to all subclasses.
        # These include defaults, fields
        class_inheritable_accessor :defaults, :fields, :required

        self.defaults = {}
        self.fields = {}
        self.required = []

        delegate :defaults, :fields, :required, :to => "self.class"
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
        access = name.to_s
        set_field(access, options)
        set_default(access, options)
        set_required(access) if options[:required]
      end

      protected
      # Define a field attribute for the +Document+.
      def set_field(name, options = {})
        meth = options.delete(:as) || name
        fields[name] = Field.new(name, options)
        create_accessors(name, meth, options)
      end

      # Create the field accessors.
      def create_accessors(name, meth, options = {})
        define_method(meth) { read_attribute(name) }
        define_method("#{meth}=") { |value| write_attribute(name, value) }
        define_method("#{meth}?") do
          attr = read_attribute(name)
          (options[:type] == Boolean) ? attr == true : attr.present?
        end
      end

      ##
      # Add fields like required by validates_presence_of
      #
      def set_required(name)
        required << name
        validates_presence_of name.to_sym
      end

      # Set up a default value for a field.
      def set_default(name, options = {})
        value = options[:default]
        defaults[name] = value unless value.nil?
      end
    end
  end
end
