require File.expand_path(File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb"))

describe Mongoid::Extensions::Time::Conversions do

  before do
    @time = Time.local(1976, 11, 19).utc
  end

  describe "#set" do
    context "when value is a string" do
      it "converts to a time" do
        Time.set(@time.to_s).should == @time
      end
    end

  end

  describe "#get" do
    it "returns the time" do
      Time.get(@time).should == @time
    end
  end

end
