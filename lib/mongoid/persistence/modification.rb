# encoding: utf-8
module Mongoid
  module Persistence

    # Contains common logic for modification operations.
    module Modification

      # Wrap all the common modification logic for both root and embedded
      # documents and then yield to the block.
      #
      # @example Execute common modification logic.
      #   prepare do |doc|
      #     collection.update({ :_id => 1 }, { :field => "value })
      #   end
      #
      # @param [ Proc ] block The block to call.
      #
      # @return [ true, false ] If the save passed or not.
      #
      # @since 2.1.0
      def prepare(&block)
        return false if validating? && document.invalid?(:update)
        result = document.run_callbacks(:save) do
          document.run_callbacks(:update) do
            yield(document); true
          end
        end
        document.post_persist unless result == false
        document.errors.clear unless validating?
        result
      end
    end
  end
end
