# encoding: utf-8
module Mongoid
  module Persistence

    # Contains common logic for upsert operations.
    module Upsertion

      # Wrap all the common upsert logic for root docments.
      #
      # @example Execute common upsert logic.
      #   prepare do |doc|
      #     collection.find({ :_id => 1 }).upsert({ name: "test" }, [ :upsert ])
      #   end
      #
      # @param [ Proc ] block The block to call.
      #
      # @return [ true, false ] If the save passed or not.
      #
      # @since 3.0.0
      def prepare(&block)
        return false if validating? && document.invalid?(:upsert)
        result = document.run_callbacks(:upsert) do
          yield(document); true
        end
        document.post_persist unless result == false
        result
      end
    end
  end
end
