# frozen_string_literal: true

module Mongoid
  module Atomic
    module Paths
      module Embedded

        # This class encapsulates behavior for locating and updating
        # documents that are defined as an embedded 1-n.
        class Many
          include Embedded

          # Create the new path utility.
          #
          # @example Create the path util.
          #   Many.new(document)
          #
          # @param [ Document ] document The document to generate the paths for.
          def initialize(document)
            @document, @parent = document, document._parent
            @insert_modifier, @delete_modifier ="$push", "$pull"
          end

          # Get the position of the document in the hierarchy. This will
          # include indexes of 1-n embedded associations that may sit above the
          # embedded many.
          #
          # @example Get the position.
          #   many.position
          #
          # @return [ String ] The position of the document.
          def position
            pos = parent.atomic_position
            locator = document.new_record? ? "" : ".#{document._index}"
            "#{pos}#{"." unless pos.blank?}#{document._association.store_as}#{locator}"
          end

          class << self

            # Get the position of where the document would go for the given
            # association. The use case for this function is when trying to
            # persist an empty list for an embedded association. All of the
            # existing functions for getting the position to store a document
            # require passing in a document to store, which we don't have when
            # trying to store the empty list.
            #
            # @param [ Document ] parent The parent document to store in.
            # @param [ Association ] association The association.
            #
            # @return [ String ] The position string.
            def position_without_document(parent, association)
              pos = parent.atomic_position
              "#{pos}#{"." unless pos.blank?}#{association.store_as}"
            end
          end
        end
      end
    end
  end
end
