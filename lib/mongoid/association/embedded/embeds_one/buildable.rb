# frozen_string_literal: true

module Mongoid
  module Association
    module Embedded
      class EmbedsOne

        # Builder class for embeds_one associations.
        module Buildable
          include Threaded::Lifecycle

          # Builds the document out of the attributes using the provided
          # association metadata on the association. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Document | Hash ] object The related document.
          # @param [ String ] _type Not used in this context.
          # @param [ Hash ] selected_fields Fields which were retrieved via
          #   #only. If selected_fields are specified, fields not listed in it
          #   will not be accessible in the built document.
          #
          # @return [ Document ] A single document.
          def build(base, object, _type = nil, selected_fields = nil)
            if object.is_a?(Hash)
              if _loading? && base.persisted?
                Factory.execute_from_db(klass, object, nil, selected_fields, execute_callbacks: false)
              else
                Factory.build(klass, object)
              end
            else
              clear_associated(object)
              object
            end
          end

          private

          def clear_associated(doc)
            if doc && (inv = inverse(doc))
              if associated = doc.ivar(inv)
                associated.substitute(nil)
              end
            end
          end
        end
      end
    end
  end
end
