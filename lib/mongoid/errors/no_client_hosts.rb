# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when a client is configured without hosts.
    class NoClientHosts < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   NoClientHosts.new(:default, {}})
      #
      # @param [ Symbol, String ] name The db config key.
      # @param [ Hash ] config The hash configuration options.
      #
      # @since 3.0.0
      def initialize(name, config)
        super(
          compose_message(
            "no_client_hosts",
            { name: name, config: config }
          )
        )
      end
    end
  end
end
