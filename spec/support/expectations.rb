# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Expectations
    def expect_query(number)
      if %i[ sharded load-balanced ].include?(ClusterConfig.instance.topology) && number > 0
        skip 'This spec requires replica set or standalone topology'
      end
      rv = nil
      RSpec::Mocks.with_temporary_scope do
        if number > 0
          expect_any_instance_of(Mongo::Server::ConnectionBase).to receive(:command_started).exactly(number).times.and_call_original
        else
          expect_any_instance_of(Mongo::Server::ConnectionBase).not_to receive(:command_started)
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
