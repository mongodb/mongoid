module Mongoid
  module Expectations

    def expect_query(number)
      # There are both start and complete events for each query.
      expect(Mongo::Logger.logger).to receive(:debug?).exactly(number * 2).times.and_call_original
      yield
    end

    def expect_no_queries(&block)
      expect_query(0, &block)
    end
  end
end
