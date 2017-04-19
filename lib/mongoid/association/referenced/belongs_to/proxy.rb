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
              characterize_one(target)
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
            target.save
          end

          # Substitutes the supplied target documents for the existing document
          # in the relation.
          #
          # @example Substitute the relation.
          #   name.substitute(new_name)
          #
          # @param [ Document, Array<Document> ] new_target The replacement.
          # @param [ true, false ] building Are we in build mode?
          #
          # @return [ In, nil ] The relation or nil.
          #
          # @since 2.0.0.rc.1
          def substitute(replacement)
            unbind_one
            return nil unless replacement
            self.target = normalize(replacement)
            bind_one
            self
          end

          private

          # Instantiate the binding associated with this relation.
          #
          # @example Get the binding object.
          #   binding([ address ])
          #
          # @param [ Document, Array<Document> ] new_target The replacement.
          #
          # @return [ Binding ] The binding object.
          #
          # @since 2.0.0.rc.1
          def binding
            BelongsTo::Binding.new(base, target, __association)
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
            __association.build(klass, replacement)
            #__association.builder(klass, replacement).build
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

            # Get the standard criteria used for querying this relation.
            #
            # @example Get the criteria.
            #   Proxy.criteria(meta, id, Model)
            #
            # @param [ Association ] association The association metadata.
            # @param [ Object ] object The value of the foreign key.
            # @param [ Class ] type The optional type.
            #
            # @return [ Criteria ] The criteria.
            #
            # @since 2.1.0
            def criteria(association, object, type = nil)
              type.where(association.primary_key => object)
            end

            # Get the Eager object for this type of association.
            #
            # @example Get the eager loader object
            #
            # @param [ Association ] The association object.
            # @param [ Array<Document> ] The array of documents.
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

            # Get the foreign key for the provided name.
            #
            # @example Get the foreign key.
            #   Association::BelongsTo::Proxy.foreign_key(:person)
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
            #   Association::BelongsTo::Proxy.foreign_key_default
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
            #   Association::BelongsTo::Proxy.foreign_key_suffix
            #
            # @return [ String ] "_id"
            #
            # @since 2.0.0.rc.1
            def foreign_key_suffix
              "_id"
            end
          end
        end
      end
    end
  end
end
