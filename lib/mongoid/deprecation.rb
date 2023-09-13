# frozen_string_literal: true
# rubocop:todo all

module Mongoid

  # Utility class for logging deprecation warnings.
  class Deprecation < ::ActiveSupport::Deprecation

    def initialize
      # Per change policy, deprecations will be removed in the next major version.
      deprecation_horizon = "#{Mongoid::VERSION.split('.').first.to_i + 1}.0".freeze
      gem_name = 'Mongoid'
      super(deprecation_horizon, gem_name)
    end


    # Overrides default ActiveSupport::Deprecation behavior
    # to use Mongoid's logger.
    #
    # @return [ Array<Proc> ] The deprecation behavior.
    def behavior
      @behavior ||= Array(->(message, callstack, _deprecation_horizon, _gem_name) {
        logger = Mongoid.logger
        logger.warn(message)
        logger.debug(callstack.join("\n  ")) if debug
      })
    end
  end
end
