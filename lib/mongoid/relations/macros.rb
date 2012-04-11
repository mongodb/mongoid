# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module contains the core macros for defining relations between
    # documents. They can be either embedded or referenced (relational).
    module Macros
      extend ActiveSupport::Concern

      included do
        class_attribute :embedded, instance_reader: false
        class_attribute :relations
        self.embedded = false
        self.relations = {}
      end

      # This is convenience for librarys still on the old API.
      #
      # @example Get the associations.
      #   person.associations
      #
      # @return [ Hash ] The relations.
      #
      # @since 2.3.1
      def associations
        self.relations
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
          if ancestors.include?(Mongoid::Versioning)
            raise Errors::VersioningNotOnRoot.new(self)
          end
          meta = characterize(name, Embedded::In, options, &block)
          self.embedded = true
          relate(name, meta)
          builder(name, meta).creator(name, meta)
          meta
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
          meta = characterize(name, Embedded::Many, options, &block)
          self.cyclic = true if options[:cyclic]
          relate(name, meta)
          validates_relation(meta)
          meta
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
          meta = characterize(name, Embedded::One, options, &block)
          self.cyclic = true if options[:cyclic]
          relate(name, meta)
          builder(name, meta).creator(name, meta)
          validates_relation(meta)
          meta
        end

        # Adds a relational association from the child Document to a Document in
        # another database or collection.
        #
        # @example Define the relation.
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     has_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def belongs_to(name, options = {}, &block)
          meta = reference_one_to_one(name, options, Referenced::In, &block)
          aliased_fields[name.to_s] = meta.foreign_key
          meta
        end

        # Adds a relational association from a parent Document to many
        # Documents in another database or collection.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     has_many :posts
        #   end
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def has_many(name, options = {}, &block)
          meta = characterize(name, Referenced::Many, options, &block)
          relate(name, meta)
          ids_getter(name, meta).ids_setter(name, meta)
          reference(meta)
          autosave(meta)
          validates_relation(meta)
          meta
        end

        # Adds a relational many-to-many association between many of this
        # Document and many of another Document.
        #
        # @example Define the relation.
        #
        #   class Person
        #     include Mongoid::Document
        #     has_and_belongs_to_many :preferences
        #   end
        #
        #   class Preference
        #     include Mongoid::Document
        #     has_and_belongs_to_many :people
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @since 2.0.0.rc.1
        def has_and_belongs_to_many(name, options = {}, &block)
          meta = characterize(name, Referenced::ManyToMany, options, &block)
          relate(name, meta)
          reference(meta, Array)
          autosave(meta)
          validates_relation(meta)
          synced(meta)
          meta
        end

        # Adds a relational association from the child Document to a Document in
        # another database or collection.
        #
        # @example Define the relation.
        #
        #   class Game
        #     include Mongoid::Document
        #     belongs_to :person
        #   end
        #
        #   class Person
        #     include Mongoid::Document
        #     has_one :game
        #   end
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Hash ] options The relation options.
        # @param [ Proc ] block Optional block for defining extensions.
        def has_one(name, options = {}, &block)
          reference_one_to_one(name, options, Referenced::One, &block)
        end

        private

        # Create the metadata for the relation.
        #
        # @api private
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
          Metadata.new({
            relation: relation,
            extend: create_extension_module(name, &block),
            inverse_class_name: self.name,
            name: name
          }.merge(options))
        end

        # Generate a named extension module suitable for marshaling
        #
        # @api private
        #
        # @example Get the module.
        #   Person.create_extension_module(:posts, &block)
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Proc ] block Optional block for defining extensions.
        #
        # @return [ Module, nil ] The extension or nil.
        #
        # @since 2.1.0
        def create_extension_module(name, &block)
          if block
            extension_module_name =
              "#{self.to_s.demodulize}#{name.to_s.camelize}RelationExtension"
            silence_warnings do
              self.const_set(extension_module_name, Module.new(&block))
            end
            "#{self}::#{extension_module_name}".constantize
          end
        end

        # Defines a field to be used as a foreign key in the relation and
        # indexes it if defined.
        #
        # @api private
        #
        # @example Set up the relational fields and indexes.
        #   Person.reference(metadata)
        #
        # @param [ Metadata ] metadata The metadata for the relation.
        def reference(metadata, type = Object)
          polymorph(metadata).cascade(metadata)
          if metadata.relation.stores_foreign_key?
            key = metadata.foreign_key
            field(
              key,
              type: type,
              identity: true,
              metadata: metadata,
              default: metadata.foreign_key_default
            )
            if metadata.indexed?
              if metadata.polymorphic?
                index(key => 1, metadata.type => 1, options: { background: true })
              else
                index(key => 1, options: { background: true })
              end
            end
          end
        end

        # Handle common behaviour for referenced 1-1 relation setup.
        #
        # @api private
        #
        # @example Add the one to one behaviour.
        #   Model.reference_one_to_one(:name, meta)
        #
        # @param [ Symbol ] name The name of the relation.
        # @param [ Metadata ] meta The relation metadata.
        #
        # @return [ Class ] The model class.
        #
        # @since 3.0.0
        def reference_one_to_one(name, options, relation, &block)
          meta = characterize(name, relation, options, &block)
          relate(name, meta)
          reference(meta)
          builder(name, meta).creator(name, meta).autosave(meta)
          validates_relation(meta)
          meta
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
          getter(name, metadata).setter(name, metadata).existence_check(name, metadata)
        end
      end
    end
  end
end
