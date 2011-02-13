# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module contains the core macros for defining relations between
    # documents. They can be either embedded or referenced (relational).
    module Macros
      extend ActiveSupport::Concern

      included do
        cattr_accessor :embedded
        class_attribute :relations
        self.embedded = false
        self.relations = {}

        # For backwards compatibility, alias the class method for associations
        # and embedding as well. Fix in related gems.
        #
        # @todo Affected libraries: Machinist
        class << self
          alias :associations :relations
          alias :embedded? :embedded
        end

        # Convenience methods for the instance to know about attributes that
        # are located at the class level.
        delegate :associations, :relations, :to => "self.class"
      end

      module ClassMethods #:nodoc:

        # Adds the relation back to the parent document. This macro is
        # necessary to set the references from the child back to the parent
        # document. If a child does not define this relation calling
        # persistence methods on the child object will cause a save to fail.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     embeds_many :addresses
        #   end
        #
        #   class Address
        #     include Mongoid::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embedded_in(name, options = {}, &block)
          characterize(name, Embedded::In, options, &block).tap do |meta|
            self.embedded = true
            relate(name, meta)
          end
        end

        # Adds the relation from a parent document to its children. The name
        # of the relation needs to be a pluralized form of the child class
        # name.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     embeds_many :addresses
        #   end
        #
        #   class Address
        #     include Mongoid::Document
        #     embedded_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embeds_many(name, options = {}, &block)
          characterize(name, Embedded::Many, options, &block).tap do |meta|
            relate(name, meta)
            validates_relation(meta)
          end
        end

        # Adds the relation from a parent document to its child. The name
        # of the relation needs to be a singular form of the child class
        # name.
        #
        # @example Define the relation.
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
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embeds_one(name, options = {}, &block)
          characterize(name, Embedded::One, options, &block).tap do |meta|
            relate(name, meta)
            builder(name).creator(name)
            validates_relation(meta)
          end
        end

        # Adds a relational association from the child Document to a Document in
        # another database or collection.
        #
        # @example Define the relation.
        #
        #   class Game
        #     include Mongoid::Document
        #     referenced_in :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     references_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def referenced_in(name, options = {}, &block)
          characterize(name, Referenced::In, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
            validates_relation(meta)
          end
        end
        alias :belongs_to_related :referenced_in
        alias :belongs_to :referenced_in

        # Adds a relational association from a parent Document to many
        # Documents in another database or collection.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     references_many :posts
        #   end
        #
        #   class Game
        #     include Mongoid::Document
        #     referenced_in :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def references_many(name, options = {}, &block)
          check_options(options)
          characterize(name, Referenced::Many, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
            autosave(meta)
            validates_relation(meta)
          end
        end
        alias :has_many_related :references_many
        alias :has_many :references_many

        # Adds a relational many-to-many association between many of this
        # Document and many of another Document.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     references_and_referenced_in_many :preferences
        #   end
        #
        #   class Preference
        #     include Mongoid::Document
        #     references_and_referenced_in_many :people
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @since 2.0.0.rc.1
        def references_and_referenced_in_many(name, options = {}, &block)
          characterize(name, Referenced::ManyToMany, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
            validates_relation(meta)
          end
        end
        alias :has_and_belongs_to_many :references_and_referenced_in_many

        # Adds a relational association from the child Document to a Document in
        # another database or collection.
        #
        # @example Define the relation.
        #
        #   class Game
        #     include Mongoid::Document
        #     referenced_in :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     references_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def references_one(name, options = {}, &block)
          characterize(name, Referenced::One, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
            builder(name).creator(name).autosave(meta)
            validates_relation(meta)
          end
        end
        alias :has_one_related :references_one
        alias :has_one :references_one

        private

        # Temporary check while people switch over to the new macro. Will be
        # deleted in 2.0.0.
        #
        # @example Check the options.
        #   Person.check_options({})
        #
        # @param [ Hash ] options The options given to the relational many.
        #
        # @raise [ RuntimeError ] If :stored_as => :array is found.
        #
        # @since 2.0.0.rc.1
        def check_options(options = {})
          if options[:stored_as] == :array
            raise RuntimeError.new(
              "Macro: references_many :name, :stored_as => :array " <<
              "Is no longer valid. Please use: references_and_referenced_in_many :name"
            )
          end
        end

        # Create the metadata for the relation.
        #
        # @example Create the metadata.
        #   Person.characterize(:posts, Referenced::Many, {})
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Object ] relation The type of relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @return [ Metadata ] The metadata for the relation.
        def characterize(name, relation, options, &block)
          Metadata.new(
            options.merge(
              :relation => relation,
              :extend => block,
              :inverse_class_name => self.name,
              :name => name
            )
          )
        end

        # Defines a field to be used as a foreign key in the relation and
        # indexes it if defined.
        #
        # @example Set up the relational fields and indexes.
        #   Person.reference(metadata)
        #
        # @param [ Metadata ] metadata The metadata for the relation.
        def reference(metadata)
          polymorph(metadata).cascade(metadata)
          if metadata.relation.stores_foreign_key?
            key = metadata.foreign_key
            field(
              key,
              :identity => true,
              :metadata => metadata,
              :default => metadata.foreign_key_default
            )
            index(key, :background => true) if metadata.indexed?
          end
        end

        # Creates a relation for the given name, metadata and relation. It adds
        # the metadata to the relations hash and has the accessors set up.
        #
        # @example Set up the relation and accessors.
        #   Person.relate(:addresses, Metadata)
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Metadata ] metadata The metadata for the relation.
        def relate(name, metadata)
          self.relations = relations.merge(name.to_s => metadata)
          getter(name, metadata).setter(name, metadata)
        end
      end
    end
  end
end
