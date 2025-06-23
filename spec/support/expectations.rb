# frozen_string_literal: true

module Mongoid
  module Expectations
    # Previously this method used RSpec::Mocks with .exactly.times(n).and_call_original,
    # which stopped working reliably in Ruby 3.3. Now we directly wrap the target method.
    def expect_query(number)
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

        result = yield
        expect(query_count).to eq(number)
        result
      ensure
        klass.remove_method(:command_started)
        klass.define_method(:command_started, original_method)
      end
    end

    def expect_no_queries(&block)
      expect_query(0, &block)
    end
  end
end
