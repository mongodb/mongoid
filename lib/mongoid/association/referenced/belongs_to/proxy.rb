# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class BelongsTo

        # This class handles all behaviour for relations that are either
        # one-to-many or one-to-one, where the foreign key is stored on this side
        # of the relation and the reference is to document(s) in another
        # collection.
        class Proxy < Association::One
          include Evolvable

          # Instantiate a new belongs_to association proxy.
          #
          # @example Create the new proxy.
          #   Association::BelongsTo::Proxy.new(game, person, association)
          #
          # @param [ Document ] base The document this relation hangs off of.
          # @param [ Document, Array<Document> ] target The target (parent) of the
          #   relation.
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
          # @example Nullify the relation.
          #   person.game.nullify
          #
          def nullify
            unbind_one
            _target.save
          end

          # Substitutes the supplied target documents for the existing document
          # in the relation.
          #
          # @example Substitute the relation.
          #   name.substitute(new_name)
          #
          # @param [ Document, Array<Document> ] replacement The replacement.
          #
          # @return [ self, nil ] The relation or nil.
          #
          # @since 2.0.0.rc.1
          def substitute(replacement)
            unbind_one
            if replacement
              self._target = normalize(replacement)
              bind_one
              self
            end
          end

          private

          # Instantiate the binding associated with this relation.
          #
          # @example Get the binding object.
          #   binding([ address ])
          #
          # @return [ Binding ] The binding object.
          #
          # @since 2.0.0.rc.1
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
          # @param [ Document, Object ] replacement The replacement object.
          #
          # @return [ Document ] The document.
          #
          # @since 3.1.5
          def normalize(replacement)
            return replacement if replacement.is_a?(Document)
            _association.build(klass, replacement)
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
            _target.persisted? && !_binding? && !_building?
          end

          class << self

            # Get the Eager object for this type of association.
            #
            # @example Get the eager loader object
            #
            # @param [ Association ] association The association object.
            # @param [ Array<Document> ] docs The array of documents.
            #
            # @since 7.0
            def eager_loader(association, docs)
              Eager.new(association, docs)
            end

            # Returns true if the relation is an embedded one. In this case
            # always false.
            #
            # @example Is this relation embedded?
            #   Association::BelongsTo::Proxy.embedded?
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
