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

      class_inheritable_accessor :associations, :cascades
      self.associations = {}
      self.cascades = {}

      delegate :embedded, :embedded?, :to => "self.class"
    end

    # Returns the associations for the +Document+.
    def associations
      self.class.associations
    end

    # are we in an embeds_many?
    def embedded_many?
      embedded? && _parent.associations[association_name].association == EmbedsMany
    end

    # are we in an embeds_one?
    def embedded_one?
      embedded? && !embedded_many?
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
          proxy = send(name)
          send("#{foreign_key}=", proxy && proxy.target ? proxy.id : nil)
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
        opts = optionize(name, options, nil, &block)
        Associations::EmbeddedIn.validate_options(opts)
        self.embedded = true
        associate(Associations::EmbeddedIn, opts)
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
        opts = optionize(name, options, nil, &block)
        Associations::EmbedsMany.validate_options(opts)
        associate(Associations::EmbedsMany, opts)
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
        type.validate_options(opts)
        associate(type, opts)
        add_builder(type, opts)
        add_creator(type, opts)
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
        Associations::ReferencedIn.validate_options(opts)
        associate(Associations::ReferencedIn, opts)
        field(opts.foreign_key, :inverse_class_name => opts.class_name, :identity => true)
        index(opts.foreign_key, :background => true) if !embedded? && opts.index
        set_callback(:save, :before) { |document| document.update_foreign_keys }
      end

      alias :belongs_to_related :referenced_in

      # Adds a relational association from the Document to many Documents in
      # another database or collection.
      #
      # Options:
      #
      # name: A +Symbol+ that is the related class name pluralized.
      # default_order: A +Criteria+ that specifies the default sort order for
      # this association. (e.g. :position.asc). If an explicit ordering is
      # specified on a +Criteria+ object, the default order will NOT be used.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     references_many :posts
      #     references_many :board_games, :default_order => :title.asc
      #   end
      #
      def references_many(name, options = {}, &block)
        reference_many(name, options, &block)
        set_callback :save, :before do |document|
          document.update_associations(name)
        end
        add_cascade(name, options)
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
        type = Associations::ReferencesOne
        associate(type, opts)
        add_builder(type, opts)
        add_creator(type, opts)
        set_callback :save, :before do |document|
          document.update_association(name)
        end
        add_cascade(name, options)
      end

      alias :has_one_related :references_one

      # Returns the association reflection object with the supplied association
      # name.
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
      end

      # Returns all association meta data for the provided type.
      #
      # Options:
      #
      # macro: The association macro.
      #
      # Example:
      #
      # <tt>Person.reflect_on_all_associations(:embeds_many)</tt>
      def reflect_on_all_associations(macro)
        associations.values.select { |meta| meta.macro == macro }
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
        define_method(name) do
          memoized(name) do
            proxy = type.new(self, options)
            case proxy
            when Associations::ReferencesOne,
                 Associations::EmbedsOne,
                 Associations::ReferencedIn,
                 Associations::EmbeddedIn
              proxy.target ? proxy : nil
            else
              proxy
            end
          end
        end
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
          reset(name) do
            proxy = type.new(self, options)
            proxy.build((attrs || {}).stringify_keys)
            proxy
          end unless type == Associations::EmbedsOne && attr_options[:update_only]
        end
      end

      # Adds a creator for a has_one association. This comes in the form of
      # create_name(attributes)
      def add_creator(type, options)
        name = options.name.to_s
        define_method("create_#{name}") do |*params|
          attrs = params[0]
          attr_options = params[1] || {}
          unless type == Associations::EmbedsOne && attr_options[:update_only]
            send("build_#{name}", attrs, attr_options).tap(&:save)
          end
        end
      end

      # Create the callbacks for dependent deletes and destroys.
      def add_cascade(name, options)
        dependent = options[:dependent]
        self.cascades[name] = dependent if dependent
      end

      # build the options given the params.
      def optionize(name, options, foreign_key, &block)
        Associations::Options.new(
          options.merge(:name => name, :foreign_key => foreign_key, :extend => block)
        )
      end

      def reference_many(name, options, &block)
        if (options[:stored_as] == :array)
          foreign_key = "#{name.to_s.singularize}_ids"
          opts = optionize(name, options, constraint(name, options, :many_as_array), &block)
          field(
            foreign_key,
            :type => Array,
            :default => [],
            :identity => true,
            :inverse_class_name => opts.class_name
          )
          index(foreign_key, :background => true) if opts.index
          associate(Associations::ReferencesManyAsArray, opts)
        else
          opts = optionize(name, options, constraint(name, options, :many), &block)
          associate(Associations::ReferencesMany, opts)
        end
      end
    end
  end
end
