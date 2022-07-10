# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class BelongsTo

        # This class handles all behavior for associations that are either
        # one-to-many or one-to-one, where the foreign key is stored on this side
        # of the association and the reference is to document(s) in another
        # collection.
        class Proxy < Association::One
          include Evolvable

          # Instantiate a new belongs_to association proxy.
          #
          # @example Create the new proxy.
          #   Association::BelongsTo::Proxy.new(game, person, association)
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Document | Array<Document> ] target The target (parent) of the
          #   association.
          # @param [ Association ] association The association object.
          def initialize(base, target, association)
            init(base, target, association) do
              characterize_one(_target)
              bind_one
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

          # Substitutes the supplied target documents for the existing document
          # in the association.
          #
          # @example Substitute the association.
          #   name.substitute(new_name)
          #
          # @param [ Document | Array<Document> ] replacement The replacement.
          #
          # @return [ self | nil ] The association or nil.
          def substitute(replacement)
            unbind_one
            if replacement
              self._target = normalize(replacement)
              bind_one
              self
            end
          end

          private

          # Instantiate the binding associated with this association.
          #
          # @example Get the binding object.
          #   binding([ address ])
          #
          # @return [ Binding ] The binding object.
          def binding
            BelongsTo::Binding.new(_base, _target, _association)
          end

          # Normalize the value provided as a replacement for substitution.
          #
          # @api private
          #
          # @example Normalize the substitute.
          #   proxy.normalize(id)
          #
          # @param [ Document | Object ] replacement The replacement object.
          #
          # @return [ Document ] The document.
          def normalize(replacement)
            return replacement if replacement.is_a?(Document)
            _association.build(klass, replacement)
          end

          # Are we able to persist this association?
          #
          # @example Can we persist the association?
          #   relation.persistable?
          #
          # @return [ true | false ] If the association is persistable.
          def persistable?
            _target.persisted? && !_binding? && !_building?
          end

          class << self

            # Get the Eager object for this type of association.
            #
            # @example Get the eager loader object
            #
            # @param [ Association ] association The association object.
            # @param [ Array<Document> ] docs The array of documents.
            def eager_loader(association, docs)
              Eager.new(association, docs)
            end

            # Returns true if the association is an embedded one. In this case
            # always false.
            #
            # @example Is this association embedded?
            #   Association::BelongsTo::Proxy.embedded?
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
