# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Macros #:nodoc:
      extend ActiveSupport::Concern

      included do
        class_inheritable_accessor :relations
        self.relations = {}
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
          relate(
            name,
            metadatafy(name, options, &block),
            Relations::Embedded::In
          )
        end

        # Adds the relation from a parent document to its children. The name
        # of the relation needs to be a pluralized form of the child class
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
          relate(
            name,
            metadatafy(name, options, &block),
            Relations::Embedded::Many
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
            metadatafy(name, options, &block),
            Relations::Embedded::One
          )
        end
        alias :embed_one :embeds_one

        def referenced_in

        end

        def references_many

        end

        def references_one

        end

        private

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
        def metadatafy(name, options, &block)
          Relations::Metadata.new(
            options.merge(
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
        # relation: The type (class) of the relation.
        def relate(name, metadata, relation)
          relations[name.to_s] = metadata
          # Define the getters and setters?
        end
      end
    end
  end
end
