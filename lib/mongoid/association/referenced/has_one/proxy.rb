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
              if __association.destructive?
                send(__association.dependent)
              else
                save if persisted?
              end
            end
            HasOne::Proxy.new(base, replacement, __association) if replacement
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
            HasOne::Binding.new(base, target, __association)
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
            # @param [ Association ] association The association metadata.
            # @param [ Document, Hash ] object A document or attributes to build
            #   with.
            #
            # @return [ Builder ] A new builder object.
            #
            # @since 2.0.0.rc.1
            def builder(base, meta, object)
              Builder.new(base, meta, object)
            end

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
              crit = association.klass.where(association.foreign_key => object)
              association.add_polymorphic_criterion(crit, type)
            end

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
          end
        end
      end
    end
  end
end
