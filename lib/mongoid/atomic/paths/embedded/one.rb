# encoding: utf-8
module Mongoid
  module Atomic
    module Paths
      module Embedded

        # This class encapsulates behaviour for locating and updating
        # documents that are defined as an embedded 1-1.
        class One
          include Embedded

          # Create the new path utility.
          #
          # @example Create the path util.
          #   One.new(document)
          #
          # @param [ Document ] document The document to generate the paths for.
          #
          # @since 2.1.0
          def initialize(document)
            @document, @parent = document, document._parent
            @insert_modifier, @delete_modifier ="$set", "$unset"
          end

          # Get the position of the document in the hierarchy. This will
          # include indexes of 1-n embedded relations that may sit above the
          # embedded one.
          #
          # @example Get the position.
          #   one.position
          #
          # @return [ String ] The position of the document.
          #
          # @since 2.1.0
          def position
            pos = parent.atomic_position
            "#{pos}#{"." unless pos.blank?}#{document.metadata.store_as}"
          end

          # Get the atomic position of the document in the hierarchy.
          # Same as position except for 1st level embedded documents.
          #
          # @example Get the atomic position.
          #   one.atomic_position
          #
          # @return [ String ] The atomic position of the document.
          #
          # @since 3.1.0
          def atomic_position
            if positionally_operable?
              position.sub(/\.\d+/, ".$")
            else
              position
            end
          end

        end
      end
    end
  end
end
