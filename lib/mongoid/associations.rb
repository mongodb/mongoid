require "mongoid/associations/decorator"
require "mongoid/associations/accessor"
require "mongoid/associations/belongs_to"
require "mongoid/associations/has_many"
require "mongoid/associations/has_one"
require "mongoid/associations/relates_to_many"
require "mongoid/associations/relates_to_one"

module Mongoid # :nodoc:
  module Associations #:nodoc:
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods
      # Returns the associations for the +Document+.
      def associations
        self.class.associations
      end

      # Updates all the relational associations for the document.
      def update_associations(name)
        send(name).each { |doc| doc.save }
      end
    end

    module ClassMethods
      def associations
        @associations ||= {}.with_indifferent_access
      end
      # Adds the association back to the parent document. This macro is
      # necessary to set the references from the child back to the parent
      # document. If a child does not define this association calling
      # persistence methods on the child object will cause a save to fail.
      #
      # Options:
      #
      # name: A +Symbol+ that matches the name of the parent class.
      #
      # Example:
      #
      #   class Person < Mongoid::Document
      #     has_many :addresses
      #   end
      #
      #   class Address < Mongoid::Document
      #     belongs_to :person, :inverse_of => :addresses
      #   end
      def belongs_to(name, options = {})
        unless options.has_key?(:inverse_of)
          raise InvalidOptionsError.new("Options for belongs_to association must include :inverse_of")
        end
        @embedded = true
        add_association(
          Associations::BelongsTo,
          Associations::Options.new(options.merge(:name => name))
        )
      end

      # Adds the association from a parent document to its children. The name
      # of the association needs to be a pluralized form of the child class
      # name.
      #
      # Options:
      #
      # name: A +Symbol+ that is the plural child class name.
      #
      # Example:
      #
      #   class Person < Mongoid::Document
      #     has_many :addresses
      #   end
      #
      #   class Address < Mongoid::Document
      #     belongs_to :person, :inverse_of => :addresses
      #   end
      def has_many(name, options = {})
        add_association(
          Associations::HasMany,
          Associations::Options.new(options.merge(:name => name))
        )
      end

      # Adds the association from a parent document to its child. The name
      # of the association needs to be a singular form of the child class
      # name.
      #
      # Options:
      #
      # name: A +Symbol+ that is the plural child class name.
      #
      # Example:
      #
      #   class Person < Mongoid::Document
      #     has_many :addresses
      #   end
      #
      #   class Address < Mongoid::Document
      #     belongs_to :person
      #   end
      def has_one(name, options = {})
        add_association(
          Associations::HasOne,
          Associations::Options.new(options.merge(:name => name))
        )
      end

      # Returns the macro associated with the supplied association name. This
      # will return has_one, has_many, belongs_to or nil.
      #
      # Options:
      #
      # name: The association name.
      #
      # Example:
      #
      # <tt>Person.reflect_on_association(:addresses)</tt>
      def reflect_on_association(name)
        association = associations[name]
        association ? association.macro : nil
      end

      # Adds a relational association from the Document to a Document in
      # another database or collection.
      #
      # Options:
      #
      # name: A +Symbol+ that is the related class name.
      #
      # Example:
      #
      #   class Person < Mongoid::Document
      #     relates_to_one :game
      #   end
      #
      def relates_to_one(name, options = {})
        field "#{name.to_s}_id"
        index "#{name.to_s}_id"
        add_association(
          Associations::RelatesToOne,
          Associations::Options.new(options.merge(:name => name))
        )
      end

      # Adds a relational association from the Document to many Documents in
      # another database or collection.
      #
      # Options:
      #
      # name: A +Symbol+ that is the related class name pluralized.
      #
      # Example:
      #
      #   class Person < Mongoid::Document
      #     relates_to_many :posts
      #   end
      #
      def relates_to_many(name, options = {})
        add_association(
          Associations::RelatesToMany,
          Associations::Options.new(options.merge(:name => name))
        )
        before_save do |document|
          document.update_associations(name)
        end
      end

      protected
      # Adds the association to the associations hash with the type as the key,
      # then adds the accessors for the association.
      def add_association(type, options)
        name = options.name
        associations[name] = type
        define_method(name) do
          return instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")
          proxy = Associations::Accessor.get(type, self, options)
          instance_variable_set("@#{name}", proxy)
        end
        define_method("#{name}=") do |object|
          proxy = Associations::Accessor.set(type, self, object, options)
          if instance_variable_defined?("@#{name}")
            remove_instance_variable("@#{name}")
          else
            instance_variable_set("@#{name}", proxy)
          end
        end
      end
    end
  end
end
