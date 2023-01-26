# frozen_string_literal: true

module Mongoid
  module Association
    module Embedded
      class EmbeddedIn

        class Proxy < Association::One

          # Instantiate a new embedded_in association.
          #
          # @example Create the new association.
          #   Association::Embedded::EmbeddedIn.new(person, address, association)
          #
          # @param [ Document ] base The document the association hangs off of.
          # @param [ Document ] target The target (parent) of the association.
          # @param [ Association ] association The association metadata.
          #
          # @return [ In ] The proxy.
          def initialize(base, target, association)
            init(base, target, association) do
              characterize_one(_target)
              bind_one
            end
          end

          # Substitutes the supplied target documents for the existing document
          # in the association.
          #
          # @example Substitute the new document.
          #   person.name.substitute(new_name)
          #
          # @param [ Document | Hash ] replacement A document to replace the target.
          #
          # @return [ Document | nil ] The association or nil.
          def substitute(replacement)
            unbind_one
            unless replacement
              _base.delete if persistable?
              return nil
            end
            _base.new_record = true
            replacement = Factory.build(klass, replacement) if replacement.is_a?(::Hash)
            self._target = replacement
            bind_one
            self
          end

          private

          # Instantiate the binding associated with this association.
          #
          # @example Get the binding.
          #   binding([ address ])
          #
          # @return [ Binding ] A binding object.
          def binding
            Binding.new(_base, _target, _association)
          end

          # Characterize the document.
          #
          # @example Set the base association.
          #   object.characterize_one(document)
          #
          # @param [ Document ] document The document to set the association metadata on.
          def characterize_one(document)
            unless _base._association
              _base._association = _association.inverse_association(document)
            end
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

            # Returns true if the association is an embedded one. In this case
            # always true.
            #
            # @example Is this association embedded?
            #   Association::Embedded::EmbeddedIn.embedded?
            #
            # @return [ true ] true.
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
            # @return [ Root ] The root atomic path calculator.
            def path(document)
              Mongoid::Atomic::Paths::Root.new(document)
            end
          end
        end
      end
    end
  end
end
