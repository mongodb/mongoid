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

    context "when value is a Date" do
      before { @date = Date.today }

      it "converts to a utc time" do
        Time.set(@date).should == Time.utc(@date.year, @date.month, @date.day)
      end
    end

    context "when value is a time" do

      it "converts to a utc time" do
        Time.set(@time).utc_offset.should == 0
      end

      it "strips miliseconds" do
        Time.set(Time.now).usec.should == 0
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

    context "when value is a ActiveSupport::TimeWithZone" do

      before do
        @time = 1.hour.ago
      end

      it "converts it to utc" do
        return unless defined? ActiveSupport::TimeWithZone
        Time.set(@time.in_time_zone("Alaska")).should == ::Time.at(@time.to_i).utc
      end

    end

    context "when a DateTime provided" do

      it "returns a time from the DateTime" do
        Date.set(@time.to_datetime).should == Time.utc(@time.year, @time.month, @time.day)
      end
    end

  end

  describe "#get" do

    context "when no time zone is set in config" do
      before do
        Mongoid::Config.instance.time_zone = nil
        Time.zone = "Stockholm"
      end

      after do
        Time.zone = nil
      end

      context "when the local time is not observing daylight saving" do
        before do
          @time = Time.zone.local(1976, 11, 19)
        end

        it "returns the local time" do
          Time.get(@time).utc_offset.should == @time.utc_offset
        end
      end

      context "when the local time is observing daylight saving" do
        before do
          @time = Time.zone.local(1976, 9, 19)
        end

        it "returns the local time" do
          Time.get(@time).utc_offset.should == @time.utc_offset
        end
      end

      context "when we have a time close to midnight" do
        before do
          @time = Time.zone.local(1976, 11, 19, 0, 30) # 0:30 am
        end

        it "does not change the day" do
          Time.get(@time).day.should == 19
        end
      end
    end

    context "when utc is set as default time zone" do
      before do
        Mongoid::Config.instance.time_zone = "UTC"
      end

      after do
         Mongoid::Config.instance.time_zone = nil
      end

      it "returns utc" do
         Time.get(@time.dup.utc).utc_offset.should == 0
      end
    end

    context "when time is nil" do

      it "returns nil" do
        Time.get(nil).should be_nil
      end

    end

  end

end
