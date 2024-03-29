# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # Raised when executing a map/reduce without specifying the output
    # location.
    class NoMapReduceOutput < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   NoMapReduceOutput.new({ map: "" })
      #
      # @param [ Hash ] command The map/reduce command.
      def initialize(command)
        super(
          compose_message("no_map_reduce_output", { command: command })
        )
      end
    end
  end
end
