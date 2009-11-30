require "spec_helper"

describe Mongoid::Extensions::DateTime::Conversions do

  before do
    Time.zone = "Eastern Time (US & Canada)"
    @time = Time.local(1976, 11, 19)
  end

  after do
    Time.zone = nil
  end

  describe "#set" do

    before do
      @date_time = DateTime.civil(2005, 11, 19).new_offset(1800)
    end

    context "when value is a string" do

      it "converts to a utc time" do
        DateTime.set(@date_time.to_s).utc_offset.should == 0
      end

    end

    context "when value is a date_time" do

      it "converts to a utc time" do
        DateTime.set(@date_time).utc_offset.should == 0
      end

    end

    context "when value is nil" do

      it "returns nil" do
        DateTime.set(nil).should be_nil
      end

    end

  end

  describe "#get" do

    context "when time is provided" do

      it "returns a DateTime" do
        DateTime.get(@time.dup).should be_a_kind_of(DateTime)
      end

      it "returns the local date_time" do
        DateTime.get(@time.dup).utc_offset.should == @time.utc_offset
      end

    end

    context "when time is nil" do

      it "returns nil" do
        DateTime.get(nil).should be_nil
      end

    end

  end

end
