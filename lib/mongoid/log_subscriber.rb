# encoding: utf-8
module Mongoid
  # A Log subscriber to the moped queries
  #
  # @since 4.0.0
  class LogSubscriber < ActiveSupport::LogSubscriber

    # Log the query operation on moped
    #
    # @since 4.0.0
    def query(event)
      return unless logger.debug?

      payload = event.payload
      runtime = ("%.4fms" % event.duration)
      debug(payload[:prefix], payload[:ops], runtime)
    end

    def query_cache(event)
      return unless logger.debug?

      database, collection, selector = event.payload[:key]
      operation = "%-12s database=%s collection=%s selector=%s" % ["QUERY CACHE", database, collection, selector.inspect]
      logger.debug operation
    end
    # Log the provided operations.
    #
    # @example Delegates the operation to moped so it can log it.
    #   subscriber.debug("MOPED", {}, 30)
    #
    # @param [ String ] prefix The prefix for all operations in the log.
    # @param [ Array ] ops The operations.
    # @param [ String ] runtime The runtime in formatted ms.
    #
    # @since 4.0.0
    def debug(prefix, operations, runtime)
      Moped::Loggable.log_operations(prefix, operations, runtime)
    end

    # Get the logger.
    #
    # @example Get the logger.
    #   subscriber.logger
    #
    # @return [ Logger ] The logger.
    #
    # @since 4.0.0
    def logger
      Moped.logger
    end
  end
end

Mongoid::LogSubscriber.attach_to :moped
Mongoid::LogSubscriber.attach_to :mongoid
