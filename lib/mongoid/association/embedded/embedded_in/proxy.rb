module Mongoid
  module Association
    module Embedded
      class EmbeddedIn

        # This class handles all behaviour for relations that are either
        # one-to-many or one-to-one, where the foreign key is store on this side
        # of the relation and the reference is to document(s) in another
        # collection.
        class Proxy < Association::One

          # Instantiate a new embedded_in relation.
          #
          # @example Create the new relation.
          #   Embedded::In.new(name, person, association)
          #
          # @param [ Document ] base The document the relation hangs off of.
          # @param [ Document ] target The target (parent) of the relation.
          # @param [ Association ] association The association metadata.
          #
          # @return [ In ] The proxy.
          def initialize(base, target, association)
            init(base, target, association) do
              characterize_one(target)
              bind_one
            end
          end

          # Substitutes the supplied target documents for the existing document
          # in the relation.
          #
          # @example Substitute the new document.
          #   person.name.substitute(new_name)
          #
          # @param [ Document ] other A document to replace the target.
          #
          # @return [ Document, nil ] The relation or nil.
          #
          # @since 2.0.0.rc.1
          def substitute(replacement)
            unbind_one
            unless replacement
              base.delete if persistable?
              return nil
            end
            base.new_record = true
            self.target = replacement
            bind_one
            self
          end

          private

          # Instantiate the binding associated with this relation.
          #
          # @example Get the binding.
          #   binding([ address ])
          #
          # @param [ Proxy ] new_target The new documents to bind with.
          #
          # @return [ Binding ] A binding object.
          #
          # @since 2.0.0.rc.1
          def binding
            Binding.new(base, target, __association)
          end

          # Characterize the document.
          #
          # @example Set the base association.
          #   relation.characterize_one(document)
          #
          # @param [ Document ] document The document to set the association metadata on.
          #
          # @since 2.1.0
          def characterize_one(document)
            unless base.__association
              base.__association = __association.inverse_association(document)
            end
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
            target.persisted? && !_binding? && !_building?
          end

          class << self

            # Return the builder that is responsible for generating the documents
            # that will be used by this relation.
            #
            # @example Get the builder.
            #   Embedded::In.builder(meta, object, person)
            #
            # @param [ Document ] base The base document.
            # @param [ Association ] association The metadata of the association.
            # @param [ Document, Hash ] object A document or attributes to build with.
            #
            # @return [ Builder ] A newly instantiated builder object.
            #
            # @since 2.0.0.rc.1
            def builder(base, association, object)
              Builder.new(base, association, object)
            end

            # Returns true if the relation is an embedded one. In this case
            # always true.
            #
            # @example Is this relation embedded?
            #   Embedded::In.embedded?
            #
            # @return [ true ] true.
            #
            # @since 2.0.0.rc.1
            def embedded?
              true
            end

            # Returns the suffix of the foreign key field, either "_id" or "_ids".
            #
            # @example Get the suffix for the foreign key.
            #   Referenced::Many.foreign_key_suffix
            #
            # @return [ nil ] nil.
            #
            # @since 3.0.0
            def foreign_key_suffix
              nil
            end

            # Returns the macro for this relation. Used mostly as a helper in
            # reflection.
            #
            # @example Get the macro.
            #   Mongoid::Relations::Embedded::In.macro
            #
            # @return [ Symbol ] :embedded_in.
            #
            # @since 2.0.0.rc.1
            def macro
              :embedded_in
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
            #   Embedded::In.stores_foreign_key?
            #
            # @return [ false ] false.
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
              VALID_OPTIONS
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
              false
            end
          end
        end
      end
    end
  end
end
