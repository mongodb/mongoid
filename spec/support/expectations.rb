# frozen_string_literal: true

module Mongoid
  module Expectations
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable RSpec/AnyInstance
    def expect_query(number)
      if %i[ sharded load-balanced ].include?(ClusterConfig.instance.topology) && number > 0
        skip 'This spec requires replica set or standalone topology'
      end

      klass = Mongo::Server::ConnectionBase
      original_method = klass.instance_method(:command_started)

      RSpec::Mocks.with_temporary_scope do
        if number > 0
          # Due to changes in Ruby 3.3, RSpec's #and_call_original (which wraps the target
          # method) causes infinite recursion. We can achieve the same behavior with binding.
          expect_any_instance_of(klass).to receive(:command_started).exactly(number).times do |*args, **kwargs|
            original_method.bind_call(*args, **kwargs)
          end
        else
          expect_any_instance_of(klass).not_to receive(:command_started)
        end

        yield
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable RSpec/AnyInstance

    def expect_no_queries(&block)
      expect_query(0, &block)
    end
  end
end
