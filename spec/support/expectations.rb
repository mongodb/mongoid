# frozen_string_literal: true

module Mongoid
  module Expectations
    # rubocop:disable Metrics/AbcSize
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
          original_method.bind(self).call(*args, **kwargs)
        end

        result = yield
        expect(query_count).to eq(number)
        result
      ensure
        klass.remove_method(:command_started)
        klass.define_method(:command_started, original_method)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def expect_no_queries(&block)
      expect_query(0, &block)
    end
  end
end
