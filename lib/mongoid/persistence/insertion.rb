# encoding: utf-8
module Mongoid
  module Persistence

    # Contains common logic for insertion operations.
    module Insertion

      # Wrap all the common insertion logic for both root and embedded
      # documents and then yield to the block.
      #
      # @example Execute common insertion logic.
      #   prepare do |doc|
      #     collection.insert({ :field => "value })
      #   end
      #
      # @param [ Proc ] block The block to call.
      #
      # @return [ Document ] The inserted document.
      #
      # @since 2.1.0
      def prepare(&block)
        unless validating? && document.invalid?(:create)
          result = document.run_callbacks(:save) do
            document.run_callbacks(:create) do
              yield(document)
              document.new_record = false
              document.flag_children_persisted
              true
            end
          end
          document.post_persist unless result == false
        end
        document.errors.clear unless validating?
        document
      end
    end
  end
end
