# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasOne

        # This class defines the behavior for all associations that are a
        # one-to-one between documents in different collections.
        class Proxy < Association::One

          # Instantiate a new references_one association. Will set the foreign key
          # and the base on the inverse object.
          #
          # @example Create the new association.
          #   Referenced::One.new(base, target, association)
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Document ] target The target (child) of the association.
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
            if replacement != self
              unbind_one
              if persistable?
                if _association.destructive?
                  send(_association.dependent)
                else
                  save if persisted?
                end
              end
            end
            if replacement
              reset_foreign_key!(replacement)
              HasOne::Proxy.new(_base, replacement, _association)
            end
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
          # @return [ true, false ] If the association is persistable.
          def persistable?
            _base.persisted? && !_binding? && !_building?
          end

          # Sets the foreign key of the replacement document to nil without
          # modifying the changed_attributes of that document.
          #
          # The use case for this function is when assigning a replacement
          # document that has a stale value for the foreign key. Previously,
          # we  would attempt to update the replacement document with the new
          # foreign key, replacing it's current value as nil in the database,
          # however, the update wouldn't be persisted because the replacement
          # document currently has a stale value that is equivalent to the
          # value of the foreign key we're trying to assign. This function,
          # clears that value and allows for any value of the foreign key to
          # persisted, regardless of the stale state of the replacement
          # document's foreign key. This function also has to update the
          # changed_attributes of the document so that the update will not
          # think that the attribute didn't change and fail to execute the
          # update.
          #
          # @param [ Document ] replacement The document to clear the value for
          #   the foreign key
          def reset_foreign_key!(replacement)
            foreign_key = _association.foreign_key
            if replacement.changed_attributes.key?(foreign_key)
              old_id = replacement.changed_attributes[_association.foreign_key]
              replacement.send(_association.foreign_key_setter, nil)
              replacement.changed_attributes[_association.foreign_key] = old_id
            else
              replacement.send(_association.foreign_key_setter, nil)
              replacement.changed_attributes.delete(_association.foreign_key)
            end
          end

          class << self

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
        end
      end
    end
  end
end
