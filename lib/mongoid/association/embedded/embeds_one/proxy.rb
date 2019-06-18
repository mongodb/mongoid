# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Embedded
      class EmbedsOne

        class Proxy < Association::One

          # The valid options when defining this association.
          #
          # @return [ Array<Symbol> ] The allowed options when defining this association.
          #
          # @since 7.0
          VALID_OPTIONS = [
              :autobuild,
              :as,
              :cascade_callbacks,
              :cyclic,
              :store_as
          ].freeze

          # Instantiate a new embeds_one association.
          #
          # @example Create the new proxy.
          #   One.new(person, name, association)
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Document ] target The child document in the association.
          # @param [ Association ] association The association metadata.
          def initialize(base, target, association)
            init(base, target, association) do
              characterize_one(_target)
              bind_one
              characterize_one(_target)
              _base._reset_memoized_children!
              _target.save if persistable?
            end
          end

          # Substitutes the supplied target documents for the existing document
          # in the association.
          #
          # @example Substitute the new document.
          #   person.name.substitute(new_name)
          #
          # @param [ Document ] replacement A document to replace the target.
          #
          # @return [ Document, nil ] The association or nil.
          #
          # @since 2.0.0.rc.1
          def substitute(replacement)
            if replacement != self
              if _assigning?
                _base.add_atomic_unset(_target) unless replacement
              else
                # The associated object will be replaced by the below update if non-nil, so only
                # run the callbacks and state-changing code by passing persist: false in that case.
                _target.destroy(persist: !replacement) if persistable?
              end
              unbind_one
              return nil unless replacement
              replacement = Factory.build(klass, replacement) if replacement.is_a?(::Hash)
              self._target = replacement
              bind_one
              characterize_one(_target)
              _target.save if persistable?
            end
            self
          end

          private

          # Instantiate the binding associated with this association.
          #
          # @example Get the binding.
          #   relation.binding([ address ])
          #
          # @return [ Binding ] The association's binding.
          #
          # @since 2.0.0.rc.1
          def binding
            Binding.new(_base, _target, _association)
          end

          # Are we able to persist this association?
          #
          # @example Can we persist the association?
          #   relation.persistable?
          #
          # @return [ true, false ] If the association is persistable.
          #
          # @since 2.1.0
          def persistable?
            _base.persisted? && !_binding? && !_building? && !_assigning?
          end

          class << self

            # Returns true if the association is an embedded one. In this case
            # always true.
            #
            # @example Is this association embedded?
            #   Association::Embedded::EmbedsOne.embedded?
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
