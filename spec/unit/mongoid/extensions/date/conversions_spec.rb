require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Date::Conversions do

  before do
    @time = Date.today.to_time.utc
  end

  describe "#set" do

    context "when string provided" do

      it "returns a time from the string" do
        Date.set(@time.to_s).should == @time
      end

    end

    context "when time provided" do

      it "returns the time" do
        Date.set(@time).should == @time
      end

    end

    context "when a date provided" do

      it "returns a time from the date" do
        Date.set(@time.to_date).should == @time
      end

    end

  end

  describe "#get" do

    it "converts the time back to a date" do
      Date.get(@time).should == @time.to_date
    end

  end

end
