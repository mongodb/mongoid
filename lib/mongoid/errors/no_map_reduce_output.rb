# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    class NoMapReduceOutput < MongoidError

      def initialize(command)
        super(
          compose_message("no_map_reduce_output", { command: command })
        )
      end
    end
  end
end
