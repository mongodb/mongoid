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
          # association metadata on the relation. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ Document ] base The document this relation hangs off of.
          # @param [ Document ] object The related document.
          # @param [ String ] _type Not used in this context.
          #
          # @return [ Document ] A single document.
          def build(base, object, _type = nil)
            return object unless object.is_a?(Hash)
            if _loading? && base.persisted?
              Factory.from_db(klass, object)
            else
              Factory.build(klass, object)
            end
          end
        end
      end
    end
  end
end
