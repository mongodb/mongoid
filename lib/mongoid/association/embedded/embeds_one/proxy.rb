module Mongoid
  module Association
    module Embedded
      class EmbedsOne

        class Proxy < Association::One

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
          #   One.new(person, name, association)
          #
          # @param [ Document ] base The document this relation hangs off of.
          # @param [ Document ] target The child document in the relation.
          # @param [ Association ] association The association metadata.
          def initialize(base, target, association)
            init(base, target, association) do
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
                # The associated object will be replaced by the below update, so only
                # run the callbacks and state-changing code by passing persist: false.
                target.destroy(persist: false) if persistable?
              end
              unbind_one
              return nil unless replacement
              replacement = Factory.build(klass, replacement) if replacement.is_a?(::Hash)
              self.target = replacement
              bind_one
              characterize_one(target)
              target.save if persistable?
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
            Binding.new(base, target, __association)
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
