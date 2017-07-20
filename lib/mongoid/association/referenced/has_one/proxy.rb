# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class HasOne

        # This class defines the behaviour for all relations that are a
        # one-to-one between documents in different collections.
        class Proxy < Association::One

          # Instantiate a new references_one relation. Will set the foreign key
          # and the base on the inverse object.
          #
          # @example Create the new relation.
          #   Referenced::One.new(base, target, association)
          #
          # @param [ Document ] base The document this relation hangs off of.
          # @param [ Document ] target The target (child) of the relation.
          # @param [ Association ] association The association metadata.
          def initialize(base, target, association)
            init(base, target, association) do
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
          # @example Nullify the relation.
          #   person.game.nullify
          #
          # @since 2.0.0.rc.1
          def nullify
            unbind_one
            _target.save
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
              if _association.destructive?
                send(_association.dependent)
              else
                save if persisted?
              end
            end
            HasOne::Proxy.new(_base, replacement, _association) if replacement
          end

          private

          # Instantiate the binding associated with this relation.
          #
          # @example Get the binding.
          #   relation.binding([ address ])
          #
          # @return [ Binding ] The binding object.
          def binding
            HasOne::Binding.new(_base, _target, _association)
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
            _base.persisted? && !_binding? && !_building?
          end

          class << self

            def eager_loader(association, docs)
              Eager.new(association, docs)
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
          end
        end
      end
    end
  end
end
