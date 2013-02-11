# encoding: utf-8
module Mongoid
  module Relations
    module Referenced

      # This class defines the behaviour for all relations that are a
      # one-to-one between documents in different collections.
      class One < Relations::One

        # Instantiate a new references_one relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # @example Create the new relation.
        #   Referenced::One.new(base, target, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Document ] target The target (child) of the relation.
        # @param [ Metadata ] metadata The relation's metadata.
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            raise_mixed if klass.embedded?
            characterize_one(target)
            bind_one
            target.save if persistable?
          end
        end

        # Removes the association between the base document and the target
        # document by deleting the foreign key and the reference, orphaning
        # the target document in the process.
        #
        # @example Nullify the relation.
        #   person.game.nullify
        #
        # @since 2.0.0.rc.1
        def nullify
          unbind_one
          target.save
        end

        # Substitutes the supplied target document for the existing document
        # in the relation. If the new target is nil, perform the necessary
        # deletion.
        #
        # @example Replace the relation.
        #   person.game.substitute(new_game)
        #
        # @param [ Array<Document> ] replacement The replacement target.
        #
        # @return [ One ] The relation.
        #
        # @since 2.0.0.rc.1
        def substitute(replacement)
          unbind_one
          if persistable?
            if metadata.destructive?
              send(metadata.dependent)
            else
              save if persisted?
            end
          end
          One.new(base, replacement, metadata) if replacement
        end

        private

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @param [ Document ] new_target The new target of the relation.
        #
        # @return [ Binding ] The binding object.
        def binding
          Bindings::Referenced::One.new(base, target, metadata)
        end

        # Are we able to persist this relation?
        #
        # @example Can we persist the relation?
        #   relation.persistable?
        #
        # @return [ true, false ] If the relation is persistable.
        #
        # @since 2.1.0
        def persistable?
          base.persisted? && !_binding? && !_building?
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::One.builder(meta, object)
          #
          # @param [ Document ] base The base document.
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(base, meta, object)
            Builders::Referenced::One.new(base, meta, object)
          end

          # Get the standard criteria used for querying this relation.
          #
          # @example Get the criteria.
          #   Proxy.criteria(meta, id, Model)
          #
          # @param [ Metadata ] metadata The metadata.
          # @param [ Object ] object The value of the foreign key.
          # @param [ Class ] type The optional type.
          #
          # @return [ Criteria ] The criteria.
          #
          # @since 2.1.0
          def criteria(metadata, object, type = nil)
            crit = metadata.klass.where(metadata.foreign_key => object)

            if metadata.polymorphic?
              crit = crit.where(metadata.type => type.name)
            end

            inverse_metadata = metadata.inverse_metadata(metadata.klass)
            if inverse_metadata.inverse_of_field
              crit = crit.any_in(inverse_metadata.inverse_of_field => [metadata.name, nil])
            end

            crit
          end

          # Get the criteria that is used to eager load a relation of this
          # type.
          #
          # @example Get the eager load criteria.
          #   Proxy.eager_load(metadata, criteria)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Array<Object> ] ids The ids of the base docs.
          #
          # @return [ Criteria ] The criteria to eager load the relation.
          #
          # @since 2.2.0
          def eager_load(metadata, ids)
            eager_load_ids(metadata, ids) { |doc, key| IdentityMap.set_one(doc, key) }
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # @example Is this relation embedded?
          #   Referenced::One.embedded?
          #
          # @return [ false ] Always false.
          #
          # @since 2.0.0.rc.1
          def embedded?
            false
          end

          # Get the foreign key for the provided name.
          #
          # @example Get the foreign key.
          #   Referenced::One.foreign_key(:person)
          #
          # @param [ Symbol ] name The name.
          #
          # @return [ String ] The foreign key.
          #
          # @since 3.0.0
          def foreign_key(name)
            "#{name}#{foreign_key_suffix}"
          end

          # Get the default value for the foreign key.
          #
          # @example Get the default.
          #   Referenced::One.foreign_key_default
          #
          # @return [ nil ] Always nil.
          #
          # @since 2.0.0.rc.1
          def foreign_key_default
            nil
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # @example Get the suffix for the foreign key.
          #   Referenced::One.foreign_key_suffix
          #
          # @return [ String ] "_id"
          #
          # @since 2.0.0.rc.1
          def foreign_key_suffix
            "_id"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the macro.
          #   Referenced::One.macro
          #
          # @return [ Symbol ] :has_one.
          def macro
            :has_one
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the nested builder.
          #   Referenced::One.builder(attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes to build with.
          # @param [ Hash ] options The options for the builder.
          #
          # @option options [ true, false ] :allow_destroy Can documents be
          #   deleted?
          # @option options [ Integer ] :limit Max number of documents to
          #   create at once.
          # @option options [ Proc, Symbol ] :reject_if If documents match this
          #   option then they are ignored.
          # @option options [ true, false ] :update_only Only existing documents
          #   can be modified.
          #
          # @return [ NestedBuilder ] A newly instantiated nested builder object.
          #
          # @since 2.0.0.rc.1
          def nested_builder(metadata, attributes, options)
            Builders::NestedAttributes::One.new(metadata, attributes, options)
          end

          # Get the path calculator for the supplied document.
          #
          # @example Get the path calculator.
          #   Proxy.path(document)
          #
          # @param [ Document ] document The document to calculate on.
          #
          # @return [ Root ] The root atomic path calculator.
          #
          # @since 2.1.0
          def path(document)
            Mongoid::Atomic::Paths::Root.new(document)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Referenced::One.stores_foreign_key?
          #
          # @return [ false ] Always false.
          #
          # @since 2.0.0.rc.1
          def stores_foreign_key?
            false
          end

          # Get the valid options allowed with this relation.
          #
          # @example Get the valid options.
          #   Relation.valid_options
          #
          # @return [ Array<Symbol> ] The valid options.
          #
          # @since 2.1.0
          def valid_options
            [ :as, :autobuild, :autosave, :dependent, :foreign_key, :primary_key ]
          end

          # Get the default validation setting for the relation. Determines if
          # by default a validates associated will occur.
          #
          # @example Get the validation default.
          #   Proxy.validation_default
          #
          # @return [ true, false ] The validation default.
          #
          # @since 2.1.9
          def validation_default
            true
          end
        end
      end
    end
  end
end
