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
      #     belongs_to :person
      #   end
      def belongs_to(name, options = {})
        @embedded = true
        add_association(Associations::BelongsTo, Options.new(options.merge(:association_name => name)))
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
      #     belongs_to :person
      #   end
      def has_many(name, options = {})
        add_association(Associations::HasMany, Options.new(options.merge(:association_name => name)))
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
        add_association(Associations::HasOne, Options.new(options.merge(:association_name => name)))
      end

      private
      # Adds the association to the associations hash with the type as the key,
      # then adds the accessors for the association.
      def add_association(type, options)
        associations[options.association_name] = type
        name = options.association_name
        define_method(name) do
          return instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")
          proxy = Associations::Accessor.get(type, self, options)
          instance_variable_set("@#{name}", proxy)
        end
        define_method("#{name}=") do |object|
          proxy = Associations::Accessor.set(type, self, object, options)
          instance_variable_set("@#{name}", proxy)
        end
      end
    end
  end
end
