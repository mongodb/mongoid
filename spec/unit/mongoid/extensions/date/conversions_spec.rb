require "spec_helper"

describe Mongoid::Extensions::Date::Conversions do
  before { @time = Time.local(2010, 11, 19) }

  describe ".set" do
    context "when given nil" do
      it "returns nil" do
        Date.set(nil).should be_nil
      end
    end

    context "when string is empty" do
      it "returns nil" do
        Date.set("").should be_nil
      end
    end

    context "when given a string" do
      it "converts to a utc time" do
        Date.set(@time.to_s).utc_offset.should == 0
      end

      it "returns the right day" do
        Date.set(@time.to_s).day.should == @time.day
      end

      it "returns a utc date from the string" do
        Date.set(@time.to_s).should == Time.utc(@time.year, @time.month, @time.day)
      end
    end

    context "when given a DateTime" do
      it "returns a time" do
        Date.set(@time.to_datetime).should == Time.utc(@time.year, @time.month, @time.day)
      end
    end

    context "when given a Time" do
      it "converts to a utc time" do
        Date.set(@time).utc_offset.should == 0
      end

      it "strips miliseconds" do
        Date.set(Time.now).usec.should == 0
      end

      it "returns utc times the same day, but at midnight" do
        Date.set(@time.utc).should == Time.utc(@time.utc.year, @time.utc.month, @time.utc.day)
      end

      it "returns the date for the time" do
        Date.set(@time).should == Time.utc(@time.year, @time.month, @time.day)
      end
    end

    context "when given an ActiveSupport::TimeWithZone" do
      before { @time = @time.in_time_zone("Canberra") }

      it "converts it to utc" do
        Date.set(@time).should == Time.utc(@time.year, @time.month, @time.day)
      end
    end

    context "when given a Date" do
      before { @date = Date.today }

      it "converts to a utc time" do
        Date.set(@date).should == Time.utc(@date.year, @date.month, @date.day)
      end
    end

    context "when given an Array" do
      before { @array = [@time.year, @time.month, @time.day] }

      it "converts to a utc time" do
        Date.set(@array).should == Time.utc(*@array)
        Date.set(@array).utc_offset.should == 0
      end
    end
  end

  describe ".get" do
    before { @time = Time.now.utc }

    it "converts the time back to a date" do
      Date.get(@time).should be_a_kind_of(Date)
    end

    context "when the time zone is not defined" do
      before do
        Mongoid::Config.instance.use_utc = false
      end

      context "when the local time is not observing daylight saving" do
        before { @time = Time.utc(2010, 11, 19) }

        it "returns the same day" do
          Date.get(@time).day.should == 19
        end
      end

      context "when the local time is observing daylight saving" do
        before { @time = Time.utc(2010, 9, 19) }

        it "returns the same day" do
          Date.get(@time).day.should == 19
        end
      end
    end

    context "when the time zone is defined as UTC" do
      before { Mongoid::Config.instance.use_utc = true }
      after { Mongoid::Config.instance.use_utc = false }

      it "returns the same day" do
         Date.get(@time.dup.utc).day.should == @time.day
      end
    end

    context "when time is nil" do
      it "returns nil" do
        Date.get(nil).should be_nil
      end
    end
  end

  describe "round trip - set then get" do
    context "when the time zone is not defined" do
      before do
        Mongoid::Config.instance.use_utc = false
        Time.zone = "Stockholm"
      end
      after { Time.zone = nil }

      context "when the local time is not observing daylight saving" do
        before { @time = Date.set(Time.zone.local(2010, 11, 19, 0, 30)) }

        it "does not change the day" do
          Date.get(@time).day.should == 19
        end
      end

      context "when the local time is observing daylight saving" do
        before { @time = Date.set(Time.zone.local(2010, 9, 19, 0, 30)) }

        it "does not change the day" do
          Date.get(@time).day.should == 19
        end
      end
    end
  end
end
