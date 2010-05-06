require "spec_helper"

describe Mongoid::Extensions::DateTime::Conversions do
  describe ".get" do
    before do
      @time = Time.now.utc
      ::Mongoid::Extensions::TimeConversions.stubs(:get).returns(@time)
    end

    it "converts to a datetime" do
      DateTime.get(@time).should be_kind_of(DateTime)
    end
  end
end
