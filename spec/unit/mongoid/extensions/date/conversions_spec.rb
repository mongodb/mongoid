require "spec_helper"

describe Mongoid::Extensions::Date::Conversions do

  before do
    @time = Date.today.to_time
  end

  describe "#set" do

    context "when string provided" do

      context "when string is a non utc time" do

        it "returns a utc time from the string" do
          Date.set(@time.to_s).should == @time.utc
        end

      end

      context "when string is a date" do

        it "returns a time from the string" do
          Date.set("01/15/2007").should == Date.new(2007, 1, 15).at_midnight.utc
        end

      end

      context "when string is empty" do

        it "returns nil" do
          Date.set("").should == nil
        end

      end

    end

    context "when time provided" do

      it "returns the time" do
        Date.set(@time).should == @time.utc
      end

    end

    context "when a date provided" do

      it "returns a time from the date" do
        Date.set(@time.to_date).should == @time
      end

    end

  end

  describe "#get" do

    context "when value is nil" do

      it "returns nil" do
        Date.get(nil).should be_nil
      end

    end

    context "when value is not nil" do

      context "when time is UTC" do

        before do
          @utc = Date.new(1974, 12, 1).to_time.utc
        end

        context "when time zone is not utc" do

          before do
            Time.zone = "Eastern Time (US & Canada)"
          end

          after do
            Time.zone = "UTC"
          end

          it "converts to the proper date" do
            Date.get(@utc).should == Date.new(1974, 12, 1)
          end

        end

      end

      it "converts the time back to a date" do
        Date.get(@time).should == @time.to_date
      end

    end

  end

end
