# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Embedded
      class EmbedsOne

        # Builder class for embeds_one associations.
        #
        # @since 7.0
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
          # @param [ Document ] object The related document.
          # @param [ String ] _type Not used in this context.
          # @param [ Hash ] selected_fields Fields which were retrieved via
          #   #only. If selected_fields are specified, fields not listed in it
          #   will not be accessible in the built document.
          #
          # @return [ Document ] A single document.
          def build(base, object, _type = nil, selected_fields = nil)
            return object unless object.is_a?(Hash)
            if _loading? && base.persisted?
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
