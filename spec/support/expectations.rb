module Mongoid
  module Expectations

    def expect_query(number)
      expect(Mongo::Logger).to receive(:allow?).with(:debug).exactly(number).times.and_call_original
      yield
    end

    def expect_no_queries(&block)
      expect_query(0, &block)
    end
  end
end
