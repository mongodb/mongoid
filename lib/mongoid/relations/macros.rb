# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Macros #:nodoc:
      extend ActiveSupport::Concern

      included do
        class_inheritable_accessor :relations
        self.relations = {}

        # Convenience methods for the instance to know about attributes that
        # are located at the class level.
        delegate :relations, :to => "self.class"
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
          relate(
            name,
            metadatafy(name, Embedded::In, options, &block)
          )
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
        #     embedded_in :person, :inverse_of => :addresses
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def embeds_many(name, options = {}, &block)
          relate(
            name,
            metadatafy(name, Embedded::Many, options, &block)
          )
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
          relate(
            name,
            metadatafy(name, Embedded::One, options, &block)
          )
          builder(name).creator(name)
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
          metadatafy(name, Referenced::In, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
          end
        end

        # Adds a relational association from the child Document to a Document in
        # another database or collection. This differs from a normal
        # referenced_in in that the foreign key is not stored on this object,
        # but in an array on the inverse side.
        #
        # @example Define the relation.
        #
        #   class Game
        #     include Mongoid::Document
        #     referenced_in_from_array :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     references_many_as_array :game
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def referenced_in_from_array(name, options = {}, &block)
          metadatafy(name, Referenced::InFromArray, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
          end
        end

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
          metadatafy(name, Referenced::Many, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
          end
        end

        # Adds a relational association from a parent Document to many
        # Documents in another database or collection, but instead of storing
        # the foreign key on the inverse objects, it gets stored on this side as
        # an array.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     references_many_as_array :posts
        #   end
        #
        #   class Game
        #     include Mongoid::Document
        #     referenced_in_from_array :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def references_many_as_array(name, options = {}, &block)
          metadatafy(name, Referenced::ManyAsArray, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
          end
        end

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
        def references_and_referenced_in_many(name, options = {}, &block)
          metadatafy(name, Referenced::ManyToMany, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
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
        def references_one(name, options = {}, &block)
          metadatafy(name, Referenced::One, options, &block).tap do |meta|
            relate(name, meta)
            reference(meta)
            builder(name).creator(name)
          end
        end

        private

        # Create the metadata for the relation.
        #
        # @example Create the metadata.
        #   Person.metadatafy(:posts, Referenced::Many, {})
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Object ] relation The type of relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @return [ Metadata ] The metadata for the relation.
        def metadatafy(name, relation, options, &block)
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
          polymorph(metadata)
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
          relations[name.to_s] = metadata
          getter(name, metadata).setter(name, metadata)
        end
      end
    end
  end
end
