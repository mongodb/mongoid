# encoding: utf-8
module Mongoid #:nodoc:
  module Attributes
    extend ActiveSupport::Concern

    # Get the id associated with this object. This will pull the _id value out
    # of the attributes +Hash+.
    def id
      @attributes["_id"]
    end

    # Set the id of the +Document+ to a new one.
    def id=(new_id)
      @attributes["_id"] = new_id
    end

    alias :_id :id
    alias :_id= :id=

    # Used for allowing accessor methods for dynamic attributes.
    def method_missing(name, *args)
      attr = name.to_s
      return super unless @attributes.has_key?(attr.reader)
      if attr.writer?
        # "args.size > 1" allows to simulate 1.8 behavior of "*args"
        write_attribute(attr.reader, (args.size > 1) ? args : args.first)
      else
        read_attribute(attr.reader)
      end
    end

    # Override respond_to? so it responds properly for dynamic attributes
    def respond_to?(*args)
      (Mongoid.allow_dynamic_fields && @attributes && @attributes.has_key?(args.first.to_s)) || super
    end

    # Process the provided attributes casting them to their proper values if a
    # field exists for them on the +Document+. This will be limited to only the
    # attributes provided in the suppied +Hash+ so that no extra nil values get
    # put into the document's attributes.
    def process(attrs = nil)
      sanitize_for_mass_assignment(attrs || {}).each_pair do |key, value|
        if set_allowed?(key)
          write_attribute(key, value)
        else
          if relations.include?(key.to_s) and relations[key.to_s].embedded? and value.is_a?(Hash)
            if relation = send(key)
              relation.metadata.nested_builder(value, {}).build(self)
            else
              send("build_#{key}", value)
            end
          else
            send("#{key}=", value)
          end
        end
      end
      setup_modifications
    end

    # Read a value from the +Document+ attributes. If the value does not exist
    # it will return nil.
    #
    # Options:
    #
    # name: The name of the attribute to get.
    #
    # Example:
    #
    # <tt>person.read_attribute(:title)</tt>
    def read_attribute(name)
      access = name.to_s
      value = @attributes[access]
      typed_value = fields.has_key?(access) ? fields[access].get(value) : value
      accessed(access, typed_value)
    end
    alias :[] :read_attribute

    # Remove a value from the +Document+ attributes. If the value does not exist
    # it will fail gracefully.
    #
    # Options:
    #
    # name: The name of the attribute to remove.
    #
    # Example:
    #
    # <tt>person.remove_attribute(:title)</tt>
    def remove_attribute(name)
      access = name.to_s
      modify(access, @attributes.delete(name.to_s), nil)
    end

    # Returns true when attribute is present.
    #
    # Options:
    #
    # name: The name of the attribute to request presence on.
    def attribute_present?(name)
      value = read_attribute(name)
      !value.blank?
    end

    # Returns the object type. This corresponds to the name of the class that
    # this +Document+ is, which is used in determining the class to
    # instantiate in various cases.
    def _type
      @attributes["_type"]
    end

    # Set the type of the +Document+. This should be the name of the class.
    def _type=(new_type)
      @attributes["_type"] = new_type
    end

    # Write a single attribute to the +Document+ attribute +Hash+. This will
    # also fire the before and after update callbacks, and perform any
    # necessary typecasting.
    #
    # Options:
    #
    # name: The name of the attribute to update.
    # value: The value to set for the attribute.
    #
    # Example:
    #
    # <tt>person.write_attribute(:title, "Mr.")</tt>
    def write_attribute(name, value)
      access = name.to_s
      modify(access, @attributes[access], typed_value_for(access, value))
    end
    alias :[]= :write_attribute

    # Writes the supplied attributes +Hash+ to the +Document+. This will only
    # overwrite existing attributes if they are present in the new +Hash+, all
    # others will be preserved.
    #
    # Options:
    #
    # attrs: The +Hash+ of new attributes to set on the +Document+
    #
    # Example:
    #
    # <tt>person.write_attributes(:title => "Mr.")</tt>
    def write_attributes(attrs = nil)
      process(attrs || {})
      identified = !id.blank?
      if new_record? && !identified
        identify
      end
    end
    alias :attributes= :write_attributes

    protected

    # Return the typecast value for a field.
    def typed_value_for(key, value)
      fields.has_key?(key) ? fields[key].set(value) : value
    end

    # apply default values to attributes - calling procs as required
    def default_attributes
      default_values = defaults
      default_values.each_pair do |key, val|
        default_values[key] = typed_value_for(key, val.call) if val.respond_to?(:call)
      end
      default_values || {}
    end

    # Return true if dynamic field setting is enabled.
    def set_allowed?(key)
      Mongoid.allow_dynamic_fields && !respond_to?("#{key}=")
    end

    # Used when supplying a :reject_if block as an option to
    # accepts_nested_attributes_for
    # def reject(attributes, options)
      # rejector = options[:reject_if]
      # if rejector
        # attributes.delete_if do |key, value|
          # rejector.call(value)
        # end
      # end
    # end

    # Used when supplying a :limit as an option to accepts_nested_attributes_for
    # def limit(attributes, name, options)
      # if options[:limit] && attributes.size > options[:limit]
        # raise Mongoid::Errors::TooManyNestedAttributeRecords.new(name, options[:limit])
      # end
    # end

    module ClassMethods
      # Defines attribute setters for the associations specified by the names.
      # This will work for a has one or has many association.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     embeds_one :name
      #     embeds_many :addresses
      #
      #     accepts_nested_attributes_for :name, :addresses
      #   end
      # def accepts_nested_attributes_for(*args)
        # associations = args.flatten
        # options = associations.last.is_a?(Hash) ? associations.pop : {}
        # associations.each do |name|
          # define_method("#{name}_attributes=") do |attrs|
            # reject(attrs, options)
            # limit(attrs, name, options)
            # association = send(name)
            # if association
              # observe(association, true)
              # association.nested_build(attrs, options)
            # else
              # send("build_#{name}", attrs, options)
            # end
          # end
        # end
      # end
    end
  end
end
