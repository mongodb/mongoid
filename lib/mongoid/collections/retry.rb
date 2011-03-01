# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    module Retry
      # Retries command on connection failures.
      #
      # This is useful when using replica sets. When a primary server wents
      # down and a command is issued, the driver will raise a
      # Mongo::ConnectionFailure. We wait a little bit, because nodes are
      # electing themselves, and then retry the given command.
      #
      # By setting Mongoid.max_retries_on_connection_failure to a value of 0,
      # no attempt will be made, immediately raising connection failure.
      # Otherwise it will attempt to make the specified number of retries
      # and then raising the exception to clients.
      def retry_on_connection_failure
        retries = 0
        begin
          yield
        rescue Mongo::ConnectionFailure => ex
          retries += 1
          raise ex if retries > Mongoid.max_retries_on_connection_failure
          Kernel.sleep(0.5)
          retry
        end
      end
    end
  end
end
