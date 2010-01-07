# encoding: utf-8
require "mongoid/associations/proxy"
require "mongoid/associations/belongs_to"
require "mongoid/associations/belongs_to_related"
require "mongoid/associations/has_many"
require "mongoid/associations/has_many_related"
require "mongoid/associations/has_one"
require "mongoid/associations/has_one_related"

module Mongoid # :nodoc:
  module Associations #:nodoc:
    def self.included(base)
      base.class_eval do
        # Associations need to inherit down the chain.
        class_inheritable_accessor :associations
        self.associations = {}.with_indifferent_access

        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods
      # Returns the associations for the +Document+.
      def associations
        self.class.associations
      end

      # Updates all the one-to-many relational associations for the name.
      def update_associations(name)
        send(name).each { |doc| doc.save }
      end

      # Update the one-to-one relational association for the name.
      def update_association(name)
        association = send(name)
        association.save unless association.nil?
      end
    end

    module ClassMethods
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
      #   class Person
      #     include Mongoid::Document
      #     has_many :addresses
      #   end
      #
      #   class Address
      #     include Mongoid::Document
      #     belongs_to :person, :inverse_of => :addresses
      #   end
      def belongs_to(name, options = {})
        unless options.has_key?(:inverse_of)
          raise Errors::InvalidOptions.new("Options for belongs_to association must include :inverse_of")
        end
        self.embedded = true
        add_association(
          Associations::BelongsTo,
          Associations::Options.new(options.merge(:name => name))
        )
      end

      # Adds a relational association from the child Document to a Document in
      # another database or collection.
      #
      # Options:
      #
      # name: A +Symbol+ that is the related class name.
      #
      # Example:
      #
      #   class Game
      #     include Mongoid::Document
      #     belongs_to_related :person
      #   end
      #
      def belongs_to_related(name, options = {})
        field "#{name.to_s}_id"
        add_association(
          Associations::BelongsToRelated,
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
      #   class Person
      #     include Mongoid::Document
      #     has_many :addresses
      #   end
      #
      #   class Address
      #     include Mongoid::Document
      #     belongs_to :person, :inverse_of => :addresses
      #   end
      def has_many(name, options = {})
        add_association(
          Associations::HasMany,
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
      #   class Person
      #     include Mongoid::Document
      #     has_many_related :posts
      #   end
      #
      def has_many_related(name, options = {})
        add_association(
          Associations::HasManyRelated,
          Associations::Options.new(options.merge(:name => name, :parent_key => self.name.foreign_key))
        )
        before_save do |document|
          document.update_associations(name)
        end
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
      #   class Person
      #     include Mongoid::Document
      #     has_many :addresses
      #   end
      #
      #   class Address
      #     include Mongoid::Document
      #     belongs_to :person
      #   end
      def has_one(name, options = {})
        opts = Associations::Options.new(options.merge(:name => name))
        type = Associations::HasOne
        add_association(type, opts)
        add_builder(type, opts)
        add_creator(type, opts)
      end

      # Adds a relational association from the Document to one Document in
      # another database or collection.
      #
      # Options:
      #
      # name: A +Symbol+ that is the related class name pluralized.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     has_one_related :game
      #   end
      def has_one_related(name, options = {})
        add_association(
          Associations::HasOneRelated,
          Associations::Options.new(options.merge(:name => name, :parent_key => self.name.foreign_key))
        )
        before_save do |document|
          document.update_association(name)
        end
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

      protected
      # Adds the association to the associations hash with the type as the key,
      # then adds the accessors for the association. The defined setters and
      # getters for the associations will perform the necessary memoization.
      def add_association(type, options)
        name = options.name
        associations[name] = type
        define_method(name) do
          memoized(name) { type.instantiate(self, options) }
        end
        define_method("#{name}=") do |object|
          reset(name) { type.update(object, self, options) }
        end
      end

      # Adds a builder for a has_one association. This comes in the form of
      # build_name(attributes)
      def add_builder(type, options)
        name = options.name
        define_method("build_#{name}") do |attrs|
          reset(name) { type.new(self, attrs, options) }
        end
      end

      # Adds a creator for a has_one association. This comes in the form of
      # create_name(attributes)
      def add_creator(type, options)
        name = options.name
        define_method("create_#{name}") do |attrs|
          document = send("build_#{name}", attrs)
          document.save; document
        end
      end
    end
  end
end
