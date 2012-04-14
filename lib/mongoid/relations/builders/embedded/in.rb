# encoding: utf-8
module Mongoid
  module Relations
    module Builders
      module Embedded
        class In < Builder

          # This builder doesn't actually build anything, just returns the
          # parent since it should already be instantiated.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type Not used in this context.
          #
          # @return [ Document ] A single document.
          def build(type = nil)
            return object unless object.is_a?(Hash)
            if _loading?
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
