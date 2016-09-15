# encoding: utf-8
module Mongoid

  # Contains logging behaviour.
  module Loggable

    # Get the logger.
    #
    # @note Will try to grab Rails' logger first before creating a new logger
    #   with stdout.
    #
    # @example Get the logger.
    #   Loggable.logger
    #
    # @return [ Logger ] The logger.
    #
    # @since 3.0.0
    def logger
      return @logger if defined?(@logger)
      @logger = rails_logger || default_logger
    end

    # Set the logger.
    #
    # @example Set the logger.
    #   Loggable.logger = Logger.new($stdout)
    #
    # @param [ Logger ] The logger to set.
    #
    # @return [ Logger ] The new logger.
    #
    # @since 3.0.0
    def logger=(logger)
      @logger = logger
    end

    private

    # Gets the default Mongoid logger - stdout.
    #
    # @api private
    #
    # @example Get the default logger.
    #   Loggable.default_logger
    #
    # @return [ Logger ] The default logger.
    #
    # @since 3.0.0
    def default_logger
      logger = Logger.new($stdout)
      logger.level = Mongoid::Config.log_level
      logger
    end

    # Get the Rails logger if it's defined.
    #
    # @api private
    #
    # @example Get Rails' logger.
    #   Loggable.rails_logger
    #
    # @return [ Logger ] The Rails logger.
    #
    # @since 3.0.0
    def rails_logger
      defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
    end
  end
end
