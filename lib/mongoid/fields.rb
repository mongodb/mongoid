# encoding: utf-8
module Mongoid #:nodoc
  module Fields #:nodoc
    extend ActiveSupport::Concern
    included do
      # Set up the class attributes that must be available to all subclasses.
      # These include defaults, fields
      class_inheritable_accessor :fields

      self.fields = {}
      delegate :defaults, :fields, :to => "self.class"
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
        attr_protected name if options[:accessible] == false
      end

      # Returns the default values for the fields on the document
      def defaults
        fields.inject({}) do |defs,(field_name,field)|
          next(defs) if field.default.nil?
          defs[field_name.to_s] = field.default
          defs
        end
      end

      protected
      # Define a field attribute for the +Document+.
      def set_field(name, options = {})
        meth = options.delete(:as) || name
        fields[name] = Field.new(name, options)
        create_accessors(name, meth, options)
        add_dirty_methods(name)
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
    end
  end
end
