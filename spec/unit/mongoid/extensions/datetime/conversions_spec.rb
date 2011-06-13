require "spec_helper"

describe Mongoid::Extensions::DateTime::Conversions do
  describe ".try_bson" do
    before do
      @time = Time.now.utc
      ::Mongoid::Extensions::TimeConversions.stubs(:get).returns(@time)
    end

    it "converts to a datetime" do
      DateTime.try_bson(@time).should be_kind_of(DateTime)
    end
  end
end
