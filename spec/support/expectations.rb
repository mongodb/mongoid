module Mongoid
  module Expectations

    def expect_query(number)
      expect(Mongo::Logger).to receive(:debug).exactly(number).times
      yield
    end

    def expect_no_queries(&block)
      expect_query(0, &block)
    end
  end
end
