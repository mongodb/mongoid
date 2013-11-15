module Mongoid
  module SpecHelpers
    def expect_query(number, &block)
      query_counter = QueryCounter.new
      query_counter.instrument(&block)
      expect(query_counter.events.size).to(eq(number), %[
Expected to receive #{number} queries, it received #{query_counter.events.size}
#{query_counter.inspect}
])
    end

    def expect_no_queries(&block)
      expect_query(0, &block)
    end
  end

  class QueryCounter
    attr_reader :events

    def initialize
      @events = []
    end

    def instrument
      subscriber = ActiveSupport::Notifications.subscribe('query.moped') do |*args|
        @events << ActiveSupport::Notifications::Event.new(*args)
      end
      yield
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    def inspect
      @events.map { |e| e.payload[:ops].map(&:log_inspect) }.join("\n")
    end
  end
end
