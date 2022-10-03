# frozen_string_literal: true

module Mongoid
  module Association
    module Embedded
      class EmbeddedIn

        # The Builder behavior for embedded_in associations.
        module Buildable
          include Threaded::Lifecycle

          # This builder doesn't actually build anything, just returns the
          # parent since it should already be instantiated.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ Document ] base The object.
          # @param [ Document | Hash ] object The parent hash or document.
          # @param [ String ] type Not used in this context.
          # @param [ Hash ] selected_fields Fields which were retrieved via
          #   #only. If selected_fields are specified, fields not listed in it
          #   will not be accessible in the built document.
          #
          # @return [ Document ] A single document.
          def build(base, object, type = nil, selected_fields = nil)
            return object unless object.is_a?(Hash)
            if _loading?
              Factory.from_db(klass, object, nil, selected_fields)
            else
              Factory.build(klass, object)
            end
          end
        end
      end
    end
  end
end
