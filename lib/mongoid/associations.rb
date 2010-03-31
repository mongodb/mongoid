# encoding: utf-8
require "mongoid/associations/proxy"
require "mongoid/associations/belongs_to_related"
require "mongoid/associations/embedded_in"
require "mongoid/associations/embeds_many"
require "mongoid/associations/embeds_one"
require "mongoid/associations/has_many_related"
require "mongoid/associations/has_one_related"
require "mongoid/associations/options"
require "mongoid/associations/meta_data"

module Mongoid # :nodoc:
  module Associations #:nodoc:
    extend ActiveSupport::Concern
    included do
      # Associations need to inherit down the chain.
      class_inheritable_accessor :associations
      self.associations = {}
    end

    module InstanceMethods
      # Returns the associations for the +Document+.
      def associations
        self.class.associations
      end

      # Updates all the one-to-many relational associations for the name.
      def update_associations(name)
        send(name).each { |doc| doc.save } if new_record?
      end

      # Update the one-to-one relational association for the name.
      def update_association(name)
        association = send(name)
        association.save if new_record? && !association.nil?
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
      #     embeds_many :addresses
      #   end
      #
      #   class Address
      #     include Mongoid::Document
      #     embedded_in :person, :inverse_of => :addresses
      #   end
      def embedded_in(name, options = {}, &block)
        unless options.has_key?(:inverse_of)
          raise Errors::InvalidOptions.new("Options for embedded_in association must include :inverse_of")
        end
        self.embedded = true
        add_association(
          Associations::EmbeddedIn,
          Associations::Options.new(
            options.merge(:name => name, :extend => block)
          )
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
      def belongs_to_related(name, options = {}, &block)
        opts = Associations::Options.new(
            options.merge(:name => name, :extend => block, :foreign_key => foreign_key(name, options))
          )
        add_association(Associations::BelongsToRelated, opts)
        field(opts.foreign_key, :type => Mongoid.use_object_ids ? Mongo::ObjectID : String)
        index(opts.foreign_key) unless self.embedded
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
      #     embeds_many :addresses
      #   end
      #
      #   class Address
      #     include Mongoid::Document
      #     embedded_in :person, :inverse_of => :addresses
      #   end
      def embeds_many(name, options = {}, &block)
        add_association(
          Associations::EmbedsMany,
          Associations::Options.new(
            options.merge(:name => name, :extend => block)
          )
        )
      end

      alias :embed_many :embeds_many

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
      def has_many_related(name, options = {}, &block)
        add_association(Associations::HasManyRelated,
          Associations::Options.new(
            options.merge(:name => name, :foreign_key => foreign_key(self.name, options), :extend => block)
          )
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
      #     embeds_one :name
      #   end
      #
      #   class Name
      #     include Mongoid::Document
      #     embedded_in :person
      #   end
      def embeds_one(name, options = {}, &block)
        opts = Associations::Options.new(
          options.merge(:name => name, :extend => block)
        )
        type = Associations::EmbedsOne
        add_association(type, opts)
        add_builder(type, opts)
        add_creator(type, opts)
      end

      alias :embed_one :embeds_one

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
      def has_one_related(name, options = {}, &block)
        add_association(
          Associations::HasOneRelated,
          Associations::Options.new(
            options.merge(:name => name, :foreign_key => foreign_key(name, options), :extend => block)
          )
        )
        before_save do |document|
          document.update_association(name)
        end
      end

      # Returns the macro associated with the supplied association name. This
      # will return embeds_on, embeds_many, embedded_in or nil.
      #
      # Options:
      #
      # name: The association name.
      #
      # Example:
      #
      # <tt>Person.reflect_on_association(:addresses)</tt>
      def reflect_on_association(name)
        association = associations[name.to_s]
        association ? association.macro : nil
      end

      protected
      # Adds the association to the associations hash with the type as the key,
      # then adds the accessors for the association. The defined setters and
      # getters for the associations will perform the necessary memoization.
      def add_association(type, options)
        name = options.name.to_s
        associations[name] = MetaData.new(type, options)
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
        name = options.name.to_s
        define_method("build_#{name}") do |attrs|
          reset(name) { type.new(self, (attrs || {}).stringify_keys, options) }
        end
      end

      # Adds a creator for a has_one association. This comes in the form of
      # create_name(attributes)
      def add_creator(type, options)
        name = options.name.to_s
        define_method("create_#{name}") do |attrs|
          document = send("build_#{name}", attrs)
          document.run_callbacks(:create) { document.save }; document
        end
      end

      # Find the foreign key.
      def foreign_key(name, options)
        options[:foreign_key] || name.to_s.foreign_key
      end
    end
  end
end
