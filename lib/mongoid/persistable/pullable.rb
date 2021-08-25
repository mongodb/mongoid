# frozen_string_literal: true

module Mongoid
  module Persistable

    # Defines behavior for $pull and $pullAll operations.
    module Pullable
      extend ActiveSupport::Concern

      # Pull single values from the provided arrays.
      #
      # @example Pull a value from the array.
      #   document.pull(names: "Jeff", levels: 5)
      #
      # @note If duplicate values are found they will all be pulled.
      #
      # @param [ Hash ] pulls The field/value pull pairs.
      #
      # @return [ Document ] The document.
      def pull(pulls)
        prepare_atomic_operation do |ops|
          process_atomic_operations(pulls) do |field, value|
            (send(field) || []).delete(value)
            ops[atomic_attribute_name(field)] = value
          end
          { "$pull" => ops }
        end
      end

      # Pull multiple values from the provided array fields.
      #
      # @example Pull values from the arrays.
      #   document.pull_all(names: [ "Jeff", "Bob" ], levels: [ 5, 6 ])
      #
      # @param [ Hash ] pulls The pull all operations.
      #
      # @return [ Document ] The document.
      def pull_all(pulls)
        prepare_atomic_operation do |ops|
          process_atomic_operations(pulls) do |field, value|
            existing = send(field) || []
            value.each{ |val| existing.delete(val) }
            ops[atomic_attribute_name(field)] = value
          end
          { "$pullAll" => ops }
        end
      end
    end
  end
end
