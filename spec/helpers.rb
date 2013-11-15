require 'mongoid/support/query_counter'

module Mongoid
  module SpecHelpers
    def expect_query(number, &block)
      query_counter = Mongoid::QueryCounter.new
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
end
