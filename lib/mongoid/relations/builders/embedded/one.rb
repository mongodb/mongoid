# encoding: utf-8
module Mongoid
  module Relations
    module Builders
      module Embedded
        class One < Builder

          # Builds the document out of the attributes using the provided
          # metadata on the relation. Instantiates through the factory in order
          # to make sure subclasses and allocation are used if fitting.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type Not used in this context.
          #
          # @return [ Document ] A single document.
          def build(type = nil)
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
