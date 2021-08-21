# frozen_string_literal: true

module Mongoid

  # Utility class for logging deprecation warnings.
  class Deprecation < ::ActiveSupport::Deprecation

    @gem_name = 'Mongoid'

    # Per change policy, deprecations will be removed in the next major version.
    @deprecation_horizon = "#{Mongoid::VERSION.split('.').first.to_i + 1}.0".freeze

    # Overrides default ActiveSupport::Deprecation behavior
    # to use Mongoid's logger.
    #
    # @return Array<Proc> The deprecation behavior.
    def behavior
      @behavior ||= Array(->(message, callstack, _deprecation_horizon, _gem_name) {
        logger = Mongoid.logger
        logger.warn(message)
        logger.debug(callstack.join("\n  ")) if debug
      })
    end
  end
end
