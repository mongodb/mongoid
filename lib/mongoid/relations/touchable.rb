# encoding: utf-8
module Mongoid
  module Relations
    module Touchable
      extend ActiveSupport::Concern

      included do
        class_attribute :touchables
        self.touchables = []
      end

      module ClassMethods

        # Add the metadata to the touchable relations if the touch option was
        # provided.
        #
        # @example Add the touchable.
        #   Model.touchable(meta)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Class ] The model class.
        #
        # @since 3.0.0
        def touchable(metadata)
          self.touchables.push(metadata.name) if metadata.touchable?
          self
        end
      end
    end
  end
end
