# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasOne
        # Transparent proxy for has_one associations.
        # An instance of this class is returned when calling the
        # association getter method on the subject document. This class
        # inherits from Mongoid::Association::Proxy and forwards most of
        # its methods to the target of the association, i.e. the
        # document on the opposite-side collection which must be loaded.
        class Proxy < Association::One
          # class-level methods for the HasOne::Proxy
          module ClassMethods
            def eager_loader(association, docs)
              Eager.new(association, docs)
            end

            # Returns true if the association is an embedded one. In this case
            # always false.
            #
            # @example Is this association embedded?
            #   Referenced::One.embedded?
            #
            # @return [ false ] Always false.
            def embedded?
              false
            end
          end

          extend ClassMethods

          # Instantiate a new references_one association. Will set the foreign key
          # and the base on the inverse object.
          #
          # @example Create the new association.
          #   Referenced::One.new(base, target, association)
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Document ] target The target (child) of the association.
          # @param [ Mongoid::Association::Relatable ] association The association metadata.
          def initialize(base, target, association)
            super do
              raise_mixed if klass.embedded? && !klass.cyclic?
              characterize_one(_target)
              bind_one
              _target.save if persistable?
            end
          end

          # Removes the association between the base document and the target
          # document by deleting the foreign key and the reference, orphaning
          # the target document in the process.
          #
          # @example Nullify the association.
          #   person.game.nullify
          def nullify
            unbind_one
            _target.save
          end

          # Substitutes the supplied target document for the existing document
          # in the association. If the new target is nil, perform the necessary
          # deletion.
          #
          # @example Replace the association.
          #   person.game.substitute(new_game)
          #
          # @param [ Array<Document> ] replacement The replacement target.
          #
          # @return [ One ] The association.
          def substitute(replacement)
            prepare_for_replacement if self != replacement
            HasOne::Proxy.new(_base, replacement, _association) if replacement
          end

          private

          # Instantiate the binding associated with this association.
          #
          # @example Get the binding.
          #   relation.binding([ address ])
          #
          # @return [ Binding ] The binding object.
          def binding
            HasOne::Binding.new(_base, _target, _association)
          end

          # Are we able to persist this association?
          #
          # @example Can we persist the association?
          #   relation.persistable?
          #
          # @return [ true | false ] If the association is persistable.
          def persistable?
            _base.persisted? && !_binding? && !_building?
          end

          # Takes the necessary steps to prepare for the current document
          # to be replaced by a non-nil substitute.
          def prepare_for_replacement
            unbind_one

            return unless persistable?

            if _association.destructive?
              send(_association.dependent)
            elsif persisted?
              save
            end
          end
        end
      end
    end
  end
end
