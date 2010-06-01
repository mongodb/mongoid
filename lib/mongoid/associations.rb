# encoding: utf-8
require "mongoid/associations/proxy"
require "mongoid/associations/embedded_in"
require "mongoid/associations/embeds_many"
require "mongoid/associations/embeds_one"
require "mongoid/associations/foreign_key"
require "mongoid/associations/references_many"
require "mongoid/associations/references_many_as_array"
require "mongoid/associations/references_one"
require "mongoid/associations/referenced_in"
require "mongoid/associations/options"
require "mongoid/associations/meta_data"

module Mongoid # :nodoc:
  module Associations #:nodoc:
    extend ActiveSupport::Concern
    included do
      include ForeignKey

      cattr_accessor :embedded
      self.embedded = false

      class_inheritable_accessor :associations
      self.associations = {}

      delegate :embedded, :embedded?, :to => "self.class"
    end

    module InstanceMethods
      # Returns the associations for the +Document+.
      def associations
        self.class.associations
      end

      # are we in an embeds_many?
      def embedded_many?
        embedded? and _parent.associations[association_name].association == EmbedsMany
      end

      # Update all the dirty child documents after an update.
      def update_embedded(name)
        association = send(name)
        association.to_a.each { |doc| doc.save if doc.changed? || doc.new_record? } unless association.blank?
      end

      # Update the one-to-one relational association for the name.
      def update_association(name)
        association = send(name)
        association.save if new_record? && !association.nil?
      end

      # Updates all the one-to-many relational associations for the name.
      def update_associations(name)
        send(name).each { |doc| doc.save } if new_record?
      end

      def update_foreign_keys
        associations.each do |name, association|
          next unless association.macro == :referenced_in
          foreign_key = association.options.foreign_key
          if send(foreign_key).nil?
            target = send(name)
            send("#{foreign_key}=", target ? target.id : nil)
          end
        end
      end
    end

    module ClassMethods
      # Gets whether or not the document is embedded.
      #
      # Example:
      #
      # <tt>Person.embedded?</tt>
      #
      # Returns:
      #
      # <tt>true</tt> if embedded, <tt>false</tt> if not.
      def embedded?
        !!self.embedded
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
        associate(Associations::EmbeddedIn, optionize(name, options, nil, &block))
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
        associate(Associations::EmbedsMany, optionize(name, options, nil, &block))
        set_callback(:update, :after) { |document| document.update_embedded(name) } unless name == :versions
      end

      alias :embed_many :embeds_many

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
        opts = optionize(name, options, nil, &block)
        type = Associations::EmbedsOne
        associate(type, opts)
        add_builder(type, opts)
        add_creator(type, opts)
        set_callback(:update, :after) { |document| document.update_embedded(name) }
      end

      alias :embed_one :embeds_one

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
      #     referenced_in :person
      #   end
      #
      def referenced_in(name, options = {}, &block)
        opts = optionize(name, options, constraint(name, options, :in), &block)
        associate(Associations::ReferencedIn, opts)
        field(opts.foreign_key, :type => Mongoid.use_object_ids ? BSON::ObjectID : String)
        index(opts.foreign_key) unless embedded?
        set_callback(:save, :before) { |document| document.update_foreign_keys }
      end

      alias :belongs_to_related :referenced_in

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
      #     references_many :posts
      #   end
      #
      def references_many(name, options = {}, &block)
        reference_many(name, options, &block)
        set_callback :save, :before do |document|
          document.update_associations(name)
        end
      end

      alias :has_many_related :references_many

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
      #     references_one :game
      #   end
      def references_one(name, options = {}, &block)
        opts = optionize(name, options, constraint(name, options, :one), &block)
        associate(Associations::ReferencesOne, opts)
        set_callback :save, :before do |document|
          document.update_association(name)
        end
      end

      alias :has_one_related :references_one

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
      #
      # Example:
      #
      # <tt>Person.associate(EmbedsMany, { :name => :addresses })</tt>
      def associate(type, options)
        name = options.name.to_s
        associations[name] = MetaData.new(type, options)
        define_method(name) { memoized(name) { type.instantiate(self, options) } }
        define_method("#{name}=") do |object|
          unmemoize(name)
          memoized(name) { type.update(object, self, options) }
        end
      end

      # Adds a builder for a has_one association. This comes in the form of
      # build_name(attributes)
      def add_builder(type, options)
        name = options.name.to_s
        define_method("build_#{name}") do |*params|
          attrs = params[0]
          attr_options = params[1] || {}
          reset(name) { type.new(self, (attrs || {}).stringify_keys, options) } unless type == Associations::EmbedsOne && attr_options[:update_only]
        end
      end

      # Adds a creator for a has_one association. This comes in the form of
      # create_name(attributes)
      def add_creator(type, options)
        name = options.name.to_s
        define_method("create_#{name}") do |*params|
          attrs = params[0]
          attr_options = params[1] || {}
          send("build_#{name}", attrs, attr_options).tap(&:save) unless type == Associations::EmbedsOne && attr_options[:update_only]
        end
      end

      # build the options given the params.
      def optionize(name, options, foreign_key, &block)
        Associations::Options.new(
          options.merge(:name => name, :foreign_key => foreign_key, :extend => block)
        )
      end

      def reference_many(name, options, &block)
        if (options[:stored_as] == :array)
          opts = optionize(name, options, constraint(name, options, :many_as_array), &block)
          field "#{name.to_s.singularize}_ids", :type => Array, :default => []
          associate(Associations::ReferencesManyAsArray, opts)
        else
          opts = optionize(name, options, constraint(name, options, :many), &block)
          associate(Associations::ReferencesMany, opts)
        end
      end
    end
  end
end
