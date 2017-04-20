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
          end
        end
      end
    end
  end
end
