require File.expand_path(File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb"))

describe Mongoid::Extensions::Time::Conversions do

  before do
    Time.zone = "Eastern Time (US & Canada)"
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

  end

  describe "#get" do

    it "returns the local time" do
      Time.get(@time.dup.utc).utc_offset.should == @time.utc_offset
    end

  end

end
