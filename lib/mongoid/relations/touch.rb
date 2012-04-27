# encoding: utf-8
module Mongoid # :nodoc:
  module Relations # :nodoc:
    module Touch
      extend ActiveSupport::Concern

      included do
        class_attribute :touches
        self.touches = []
      end

      # Touch all document where relation
      # is define like touch
      #
      # @return [ Array ] list of relation touch
      #
      # @since 3.0.0
      def cascade_touch!
        touches.each do |name|
          meta = relations[name]
          if meta.touch?
            relation = send(meta.name)
            relation.touch  if relation
          end
        end
      end

      module ClassMethods

        # Attempt to add the touch information for the document to know how
        # to handle associated documents on a updating document.
        #
        # @example Set up cascading information
        #   Movie.touch(metadata)
        #
        # @param [ Metadata ] metadata The metadata for the relation.
        #
        # @return [ Class ] The class of the document.
        #
        # @since 3.0.0
        def touch(metadata)
          self.touches += [ metadata.name.to_s ] if metadata.touch?
          self
        end
      end
    end
  end
end
