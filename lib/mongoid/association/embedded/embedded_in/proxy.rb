# frozen_string_literal: true
# encoding: utf-8

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
          # @param [ Document ] replacement A document to replace the target.
          #
          # @return [ Document, nil ] The association or nil.
          #
          # @since 2.0.0.rc.1
          def substitute(replacement)
            unbind_one
            unless replacement
              _base.delete if persistable?
              return nil
            end
            _base.new_record = true
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
          #
          # @since 2.0.0.rc.1
          def binding
            Binding.new(_base, _target, _association)
          end

          # Characterize the document.
          #
          # @example Set the base association.
          #   object.characterize_one(document)
          #
          # @param [ Document ] document The document to set the association metadata on.
          #
          # @since 2.1.0
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
          # @return [ true, false ] If the association is persistable.
          #
          # @since 2.1.0
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
            # @return [ Root ] The root atomic path calculator.
            #
            # @since 2.1.0
            def path(document)
              Mongoid::Atomic::Paths::Root.new(document)
            end
          end
        end
      end
    end
  end
end
