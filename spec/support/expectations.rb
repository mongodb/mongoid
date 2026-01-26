# frozen_string_literal: true

module Mongoid
  module Expectations
    # Previously this method used RSpec::Mocks with .exactly.times(n).and_call_original,
    # which stopped working reliably in Ruby 3.3. Now we directly wrap the target method.
    def expect_query(number, &test_block)
      count_queries_and_verify(number, test_block) do |query_count|
        expect(query_count).to eq(number)
      end
    end

    def expect_less_than_queries(maximum, &test_block)
      count_queries_and_verify(maximum, test_block) do |query_count|
        expect(query_count).to be < maximum
      end
    end

    def expect_no_queries(&test_block)
      expect_query(0, &test_block)
    end

    private

    def count_queries_and_verify(number, test_block)
      if %i[ sharded load-balanced ].include?(ClusterConfig.instance.topology) && number > 0
        skip 'This spec requires replica set or standalone topology'
      end

      klass = Mongo::Server::ConnectionBase
      original_method = klass.instance_method(:command_started)
      query_count = 0

      begin
        klass.define_method(:command_started) do |*args, **kwargs|
          query_count += 1
          original_method.bind_call(self, *args, **kwargs)
        end

        result = test_block.call
        yield query_count
        result
      ensure
        klass.remove_method(:command_started)
        klass.define_method(:command_started, original_method)
      end
    end
  end
end
