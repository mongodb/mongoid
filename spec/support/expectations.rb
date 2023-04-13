# frozen_string_literal: true

module Mongoid
  module Expectations

    def connection_class
      Mongo::Server::ConnectionBase
    end

    def expect_query(number, skip_if_sharded: false)
      if skip_if_sharded && number > 0 && ClusterConfig.instance.topology == :sharded
        skip 'MONGOID-5599: Sharded clusters do extra read queries, causing expect_query to fail.'
      end

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
