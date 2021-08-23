# frozen_string_literal: true

module Mongoid
  module Expectations

    def connection_class
      if defined?(Mongo::Server::ConnectionBase)
        Mongo::Server::ConnectionBase
      else
        # Pre-2.8 drivers
        Mongo::Server::Connection
      end
    end

    def expect_query(number)
      rv = nil
      RSpec::Mocks.with_temporary_scope do
        if number > 0
          expect_any_instance_of(connection_class).to receive(:command_started).exactly(number).times.and_call_original
        else
          expect_any_instance_of(connection_class).not_to receive(:command_started)
        end
        rv = yield
      end
      rv
    end

    def expect_no_queries(&block)
      expect_query(0, &block)
    end
  end
end
