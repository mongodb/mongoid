# frozen_string_literal: true

module Mongoid
  module Errors
    # This error is raised when evaluating a query in memory exceeds
    # Mongoid::Config.in_memory_regexp_time_limit.
    #
    # What the limit bounds depends on the Ruby in use. Where per-Regexp
    # timeouts are available it is the time spent executing regular
    # expressions; elsewhere it is the elapsed time of the whole in-memory
    # evaluation. The message is worded to hold either way.
    class InMemoryRegexpTimeout < MongoidError
      # Create the new error.
      #
      # @example Create the new in-memory regexp timeout error.
      #   InMemoryRegexpTimeout.new(5.0)
      #
      # @param [ Float ] limit The limit that was exceeded, in seconds. Not
      #   always the configured one: a global Regexp.timeout stricter than the
      #   configuration takes its place.
      def initialize(limit)
        super(compose_message('in_memory_regexp_timeout', limit: limit))
      end
    end
  end
end
