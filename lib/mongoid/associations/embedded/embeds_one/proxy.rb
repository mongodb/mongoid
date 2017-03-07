module Mongoid
  module Associations
    module Embedded
      class EmbedsOne

        class Proxy < Associations::One

          # The allowed options when defining this relation.
          #
          # @return [ Array<Symbol> ] The allowed options when defining this relation.
          #
          # @since 6.0.0
          VALID_OPTIONS = [
              :autobuild,
              :as,
              :cascade_callbacks,
              :cyclic,
              :store_as
          ].freeze

          # Instantiate a new embeds_one relation.
          #
          # @example Create the new proxy.
          #   One.new(person, name, metadata)
          #
          # @param [ Document ] base The document this relation hangs off of.
          # @param [ Document ] target The child document in the relation.
          # @param [ Metadata ] metadata The relation's metadata
          def initialize(base, target, metadata)
            init(base, target, metadata) do
              characterize_one(target)
              bind_one
              characterize_one(target)
              base._reset_memoized_children!
              target.save if persistable?
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
            if replacement != self
              if _assigning?
                base.add_atomic_unset(target) unless replacement
              else
                target.destroy if persistable?
              end
              unbind_one
              return nil unless replacement
              replacement = Factory.build(klass, replacement) if replacement.is_a?(::Hash)
              self.target = replacement
              bind_one
              characterize_one(target)
              target.save if persistable? && !_assigning?
            end
            self
          end

          private

          # Instantiate the binding associated with this relation.
          #
          # @example Get the binding.
          #   relation.binding([ address ])
          #
          # @param [ Document ] new_target The new document to bind with.
          #
          # @return [ Binding ] The relation's binding.
          #
          # @since 2.0.0.rc.1
          def binding
            Binding.new(base, target, __metadata)
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
            base.persisted? && !_binding? && !_building? && !_assigning?
          end

          class << self

            # Return the builder that is responsible for generating the documents
            # that will be used by this relation.
            #
            # @example Get the builder.
            #   Embedded::One.builder(meta, object, person)
            #
            # @param [ Document ] base The base document.
            # @param [ Metadata ] meta The metadata of the relation.
            # @param [ Document, Hash ] object A document or attributes to build with.
            #
            # @return [ Builder ] A newly instantiated builder object.
            #
            # @since 2.0.0.rc.1
            def builder(base, meta, object)
              Builder.new(base, meta, object)
            end

            # Returns true if the relation is an embedded one. In this case
            # always true.
            #
            # @example Is this relation embedded?
            #   Embedded::One.embedded?
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

            # Get the path calculator for the supplied document.
            #
            # @example Get the path calculator.
            #   Proxy.path(document)
            #
            # @param [ Document ] document The document to calculate on.
            #
            # @return [ Mongoid::Atomic::Paths::Embedded::One ]
            #   The embedded one atomic path calculator.
            #
            # @since 2.1.0
            def path(document)
              Mongoid::Atomic::Paths::Embedded::One.new(document)
            end
          end
        end
      end
    end
  end
end
