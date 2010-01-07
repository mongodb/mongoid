require "spec_helper"

describe Mongoid::Extensions::Time::Conversions do

  before do
    Time.zone = "Canberra"
    @time = Time.local(1976, 11, 19)
  end

  after do
    Time.zone = nil
  end

  describe "#set" do

    context "when value is a string" do

      it "converts to a utc time" do
        Time.set(@time.to_s).utc_offset.should == 0
      end

    end

    context "when value is a time" do

      it "converts to a utc time" do
        Time.set(@time).utc_offset.should == 0
      end

    end

    context "when value is already a utc time" do

      it "returns the time" do
        Time.set(@time.utc).should == @time.utc
      end

    end

    context "when value is nil" do

      it "returns nil" do
        Time.set(nil).should be_nil
      end

    end

  end

  describe "#get" do

    context "when time is provided" do

      it "returns the local time" do
        Time.get(@time.dup.utc).utc_offset.should == @time.utc_offset
      end

    end

    context "when time is nil" do

      it "returns nil" do
        Time.get(nil).should be_nil
      end

    end

  end

end
