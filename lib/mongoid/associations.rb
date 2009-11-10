require "mongoid/associations/decorator"
require "mongoid/associations/accessor"
require "mongoid/associations/belongs_to"
require "mongoid/associations/has_many"
require "mongoid/associations/has_one"

module Mongoid # :nodoc:
  module Associations #:nodoc:
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods
      def associations
        self.class.associations
      end
    end

    module ClassMethods
      def associations
        @associations ||= HashWithIndifferentAccess.new
      end
      # Adds the association back to the parent document. This macro is
      # necessary to set the references from the child back to the parent
      # document. If a child does not define this association calling
      # persistence methods on the child object will cause a save to fail.
      #
      # Options:
      #
      # association_name: A +Symbol+ that matches the name of the parent class.
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
      def belongs_to(association_name, options = {})
        @embedded = true
        add_association(Associations::BelongsTo, association_name, options)
      end

      # Adds the association from a parent document to its children. The name
      # of the association needs to be a pluralized form of the child class
      # name.
      #
      # Options:
      #
      # association_name: A +Symbol+ that is the plural child class name.
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
      def has_many(association_name, options = {})
        add_association(Associations::HasMany, association_name, options)
      end

      # Adds the association from a parent document to its child. The name
      # of the association needs to be a singular form of the child class
      # name.
      #
      # Options:
      #
      # association_name: A +Symbol+ that is the plural child class name.
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
      def has_one(association_name, options = {})
        add_association(Associations::HasOne, association_name, options)
      end

      private
      # Adds the association to the associations hash with the type as the key,
      # then adds the accessors for the association.
      def add_association(type, name, options = {})
        associations[name] = type
        define_method(name) do
          return instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")
          proxy = Associations::Accessor.get(type, name, self, options)
          instance_variable_set("@#{name}", proxy)
        end
        define_method("#{name}=") do |object|
          proxy = Associations::Accessor.set(type, name, self, object, options)
          instance_variable_set("@#{name}", proxy)
        end
      end
    end
  end
end
