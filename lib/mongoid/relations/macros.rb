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
        # Options:
        #
        # name: A +Symbol+ that matches the name of the parent class.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
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
          self.embedded = true
          relate(
            name,
            metadatafy(name, Relations::Embedded::In, options, &block)
          )
        end

        # Adds the relation from a parent document to its children. The name
        # of the relation needs to be a pluralized form of the child class
        # name.
        #
        # Options:
        #
        # name: A +Symbol+ that is the plural child class name.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
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
          relate(
            name,
            metadatafy(name, Relations::Embedded::Many, options, &block)
          )
        end
        alias :embed_many :embeds_many

        # Adds the relation from a parent document to its child. The name
        # of the relation needs to be a singular form of the child class
        # name.
        #
        # Options:
        #
        # name: A +Symbol+ that is the plural child class name.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
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
          relate(
            name,
            metadatafy(name, Relations::Embedded::One, options, &block)
          )
          builder(name).creator(name)
        end
        alias :embed_one :embeds_one

        # Adds a relational association from the child Document to a Document in
        # another database or collection.
        #
        # Options:
        #
        # name: A +Symbol+ that is the related class name.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
        #
        # Example:
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
        def referenced_in(name, options = {}, &block)
          metadata = metadatafy(
            name,
            Relations::Referenced::In,
            options,
            &block
          )
          relate(name, metadata)
          reference(metadata)
        end

        # Adds a relational association from the child Document to a Document in
        # another database or collection. This differs from a normal
        # referenced_in in that the foreign key is not stored on this object,
        # but in an array on the inverse side.
        #
        # Options:
        #
        # name: A +Symbol+ that is the related class name.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
        #
        # Example:
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
        def referenced_in_from_array(name, options = {}, &block)
          relate(
            name,
            metadatafy(name, Relations::Referenced::InFromArray, options, &block)
          )
        end

        # Adds a relational association from a parent Document to many
        # Documents in another database or collection.
        #
        # Options:
        #
        # name: A +Symbol+ that is the related class name.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
        #
        # Example:
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
        def references_many(name, options = {}, &block)
          relate(
            name,
            metadatafy(name, Relations::Referenced::Many, options, &block)
          )
        end

        # Adds a relational association from a parent Document to many
        # Documents in another database or collection, but instead of storing
        # the foreign key on the inverse objects, it gets stored on this side as
        # an array.
        #
        # Options:
        #
        # name: A +Symbol+ that is the related class name.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
        #
        # Example:
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
        def references_many_as_array(name, options = {}, &block)
          metadata = metadatafy(
            name,
            Relations::Referenced::ManyAsArray,
            options,
            &block
          )
          relate(name, metadata)
          reference(metadata)
        end

        # Adds a relational many-to-many association between many of this
        # Document and many of another Document.
        #
        # Options:
        #
        # name: A +Symbol+ that is the related class name.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
        #
        # Example:
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
        def references_and_referenced_in_many(name, options = {}, &block)
          metadata = metadatafy(
            name,
            Relations::Referenced::ManyToMany,
            options,
            &block
          )
          relate(name, metadata)
          reference(metadata)
        end

        # Adds a relational association from the child Document to a Document in
        # another database or collection.
        #
        # Options:
        #
        # name: A +Symbol+ that is the related class name.
        # options: The relation options as a +Hash+.
        # block: Optional block for defining relation extensions.
        #
        # Example:
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
        def references_one(name, options = {}, &block)
          relate(
            name,
            metadatafy(name, Relations::Referenced::One, options, &block)
          )
        end

        private

        # Defines a field to be used as a foreign key in the relation and
        # indexes it if defined.
        #
        # Example:
        #
        # <tt>Person.reference(metadata)</tt>
        #
        # Options:
        #
        # metadata: The metadata for the relation.
        def reference(metadata)
          if metadata.relation.stores_foreign_key?
            key = metadata.foreign_key
            field(key)
            index(key, :background => true) if metadata.indexed?
          end
        end

        # Create the metadata for the relation.
        #
        # Options:
        #
        # name: The name of the relation.
        # options: The hash of options provided to the macro.
        # block: Optional block to use as an extension.
        #
        # Returns:
        #
        # A +Relations::Metadata+ object for this relation.
        def metadatafy(name, relation, options, &block)
          Relations::Metadata.new(
            options.merge(
              :relation => relation,
              :extend => block,
              :inverse_class_name => self.name,
              :name => name
            )
          )
        end

        # Creates a relation for the given name, metadata and relation. It adds
        # the metadata to the relations hash and has the accessors set up.
        #
        # Options:
        #
        # name: The name of the relation.
        # metadata: The metadata for the relation.
        def relate(name, metadata)
          relations[name.to_s] = metadata
          getter(name, metadata).setter(name, metadata)
        end
      end
    end
  end
end
