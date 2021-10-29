# frozen_string_literal: true

module Mongoid

  # Contains logging behavior.
  module Loggable

    # Get the logger.
    #
    # @note Will try to grab Rails' logger first before creating a new logger
    #   with stderr.
    #
    # @example Get the logger.
    #   Loggable.logger
    #
    # @return [ Logger ] The logger.
    def logger
      return @logger if defined?(@logger)
      @logger = rails_logger || default_logger
    end

    # Set the logger.
    #
    # @example Set the logger.
    #   Loggable.logger = Logger.new(STDERR)
    #
    # @param [ Logger ] logger The logger to set.
    #
    # @return [ Logger ] The new logger.
    def logger=(logger)
      @logger = logger
    end

    private

    # Gets the default Mongoid logger - stderr.
    #
    # @api private
    #
    # @example Get the default logger.
    #   Loggable.default_logger
    #
    # @return [ Logger ] The default logger.
    def default_logger
      logger = Logger.new(STDERR)
      logger.level = Mongoid::Config.log_level
      logger
    end

    # Get the Rails logger if loaded in a Rails application, otherwise nil.
    #
    # @api private
    #
    # @example Get Rails' logger.
    #   Loggable.rails_logger
    #
    # @return [ Logger ] The Rails logger.
    def rails_logger
      if defined?(::Rails)
        ::Rails.logger
      else
        nil
      end
    end
  end
end
