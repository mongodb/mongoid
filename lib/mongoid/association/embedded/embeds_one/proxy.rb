# frozen_string_literal: true

module Mongoid
  module Association
    module Embedded
      class EmbedsOne
        # Transparent proxy for embeds_one associations.
        # An instance of this class is returned when calling the
        # association getter method on the parent document. This
        # class inherits from Mongoid::Association::Proxy and forwards
        # most of its methods to the target of the association, i.e.
        # the child document.
        class Proxy < Association::One
          # The valid options when defining this association.
          #
          # @return [ Array<Symbol> ] The allowed options when defining this association.
          VALID_OPTIONS = %i[
            autobuild
            as
            cascade_callbacks
            cyclic
            store_as
          ].freeze

          # Instantiate a new embeds_one association.
          #
          # @example Create the new proxy.
          #   One.new(person, name, association)
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Document ] target The child document in the association.
          # @param [ Mongoid::Association::Relatable ] association The association metadata.
          def initialize(base, target, association)
            super do
              characterize_one(_target)
              bind_one
              characterize_one(_target)
              update_attributes_hash(_target)
              _base._reset_memoized_descendants!
              _target.save if persistable?
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
            return self if replacement == self

            if _assigning?
              _base.add_atomic_unset(_target) unless replacement
            else
              update_target_when_not_assigning(replacement)
            end

            unbind_one

            return nil if replace_with_nil_document(replacement)

            replace_with(replacement)

            self
          end

          private

          # Instantiate the binding associated with this association.
          #
          # @example Get the binding.
          #   relation.binding([ address ])
          #
          # @return [ Binding ] The association's binding.
          def binding
            Binding.new(_base, _target, _association)
          end

          # Are we able to persist this association?
          #
          # @example Can we persist the association?
          #   relation.persistable?
          #
          # @return [ true | false ] If the association is persistable.
          def persistable?
            _base.persisted? && !_binding? && !_building? && !_assigning?
          end

          # Update the _base's attributes hash with the _target's attributes
          #
          # @param replacement [ Document | nil ] The doc to use to update the
          #   attributes hash.
          #
          # @api private
          def update_attributes_hash(replacement)
            if replacement
              _base.attributes.merge!(_association.store_as => replacement.attributes)
            else
              _base.attributes.delete(_association.store_as)
            end
          end

          # When not ``_assigning?``, the target may need to be destroyed, and
          # may need to be marked as a new record. This method takes care of
          # that, with extensive documentation for why it is necessary.
          #
          # @param [ Mongoid::Document ] replacement the replacement document
          def update_target_when_not_assigning(replacement)
            # The associated object will be replaced by the below update if non-nil, so only
            # run the callbacks and state-changing code by passing persist: false in that case.
            _target.destroy(persist: !replacement) if persistable?

            # A little explanation on why this is needed... Say we have three assignments:
            #
            # canvas.palette = palette
            # canvas.palette = nil
            # canvas.palette = palette
            # Where canvas embeds_one palette.
            #
            # Previously, what was happening was, on the first assignment,
            # palette was considered a "new record" (new_record?=true) and
            # thus palette was being inserted into the database. However,
            # on the third assignment, we're trying to reassign the palette,
            # palette is no longer considered a new record, because it had
            # been inserted previously. This is not exactly accurate,
            # because the second assignment ultimately removed the palette
            # from the database, so it needs to be reinserted. Since the
            # palette's new_record is false, Mongoid ends up "updating" the
            # document, which doesn't reinsert it into the database.
            #
            # The change I introduce here, respecifies palette as a "new
            # record" when it gets removed from the database, so if it is
            # reassigned, it will be reinserted into the database.
            _target.new_record = true
          end

          # Checks the argument. If it is non-nil, this method does nothing.
          # Otherwise, it performs the logic for replacing the current
          # document with nil.
          #
          # @param [ Mongoid::Document | Hash | nil ] replacement the document
          #   to check.
          #
          # @return [ true | false ] whether a nil document was substituted
          #   or not.
          def replace_with_nil_document(replacement)
            return false if replacement

            update_attributes_hash(replacement)

            # when `touch: true` is the default (see MONGOID-5016), creating
            # an embedded document will touch the parent, and will cause the
            # _descendants list to be initialized and memoized. If the object
            # is then deleted, we need to make sure and un-memoize that list,
            # otherwise when the update happens, the memoized _descendants list
            # gets used and the "deleted" subdocument gets added again.
            _reset_memoized_descendants!

            true
          end

          # Replaces the current document with the given replacement
          # document, which may be a Hash of attributes.
          #
          # @param [ Mongoid::Document | Hash ] replacement the document to
          #   substitute in place of the current document.
          def replace_with(replacement)
            replacement = Factory.build(klass, replacement) if replacement.is_a?(::Hash)
            self._target = replacement
            characterize_one(_target)
            bind_one
            update_attributes_hash(_target)
            _target.save if persistable?
          end

          class << self
            # Returns the eager loader for this association.
            #
            # @param [ Array<Mongoid::Association> ] associations The
            #   associations to be eager loaded
            # @param [ Array<Mongoid::Document> ] docs The parent documents
            #   that possess the given associations, which ought to be
            #   populated by the eager-loaded documents.
            #
            # @return [ Mongoid::Association::Embedded::Eager ]
            def eager_loader(associations, docs)
              Eager.new(associations, docs)
            end

            # Returns true if the association is an embedded one. In this case
            # always true.
            #
            # @example Is this association embedded?
            #   Association::Embedded::EmbedsOne.embedded?
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
            # @return [ Mongoid::Atomic::Paths::Embedded::One ]
            #   The embedded one atomic path calculator.
            def path(document)
              Mongoid::Atomic::Paths::Embedded::One.new(document)
            end
          end
        end
      end
    end
  end
end
