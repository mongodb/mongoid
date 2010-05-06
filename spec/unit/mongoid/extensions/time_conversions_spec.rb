require "spec_helper"

describe Mongoid::Extensions::TimeConversions do
  before do
    Time.zone = "Canberra"
    @time = Time.local(2010, 11, 19)
  end

  after { Time.zone = nil }

  describe ".set" do
    context "when given nil" do
      it "returns nil" do
        Time.set(nil).should be_nil
      end
    end

    context "when string is empty" do
      it "returns nil" do
        Time.set("").should be_nil
      end
    end

    context "when given a string" do
      it "converts to a utc time" do
        Time.set(@time.to_s).utc_offset.should == 0
      end

      it "returns the wrong day due to a limitation in Time.parse: it ignores the time zone" do
        Time.set(@time.to_s).day.should == (@time.day - 1)
      end

      it "returns a local date from the string due to a limitation in Time.parse" do
        Time.set(@time.to_s).should == Time.local(@time.year, @time.month, @time.day, @time.hour, @time.min, @time.sec)
      end
    end

    context "when given a DateTime" do
      it "returns a time" do
        Time.set(@time.to_datetime).should == Time.utc(@time.year, @time.month, @time.day, @time.hour, @time.min, @time.sec)
      end
    end

    context "when given a Time" do
      it "converts to a utc time" do
        Time.set(@time).utc_offset.should == 0
      end

      it "strips miliseconds" do
        Time.set(Time.now).usec.should == 0
      end

      it "returns utc times unchanged" do
        Time.set(@time.utc).should == @time.utc
      end
      
      it "returns the time as utc" do
        Time.set(@time).should == @time.utc
      end
    end

    context "when given an ActiveSupport::TimeWithZone" do
      before { @time = 1.hour.ago }

      it "converts it to utc" do
        Time.set(@time.in_time_zone("Alaska")).should == Time.at(@time.to_i).utc
      end
    end

    context "when given a Date" do
      before { @date = Date.today }

      it "converts to a utc time" do
        Time.set(@date).should == Time.utc(@date.year, @date.month, @date.day)
      end
    end
  end

  describe ".get" do
    context "when the time zone is not defined" do
      before do
        Mongoid::Config.instance.time_zone = nil
        Time.zone = "Stockholm"
      end

      context "when the local time is not observing daylight saving" do
        before { @time = Time.utc(2010, 11, 19) }

        it "returns the local time" do
          Time.get(@time).utc_offset.should == Time.zone.utc_offset
        end
      end

      context "when the local time is observing daylight saving" do
        before { @time = Time.utc(2010, 9, 19) }

        it "returns the local time" do
          Time.get(@time).utc_offset.should == Time.zone.utc_offset + 3600
        end
      end

      context "when we have a time close to midnight" do
        before { @time = Time.zone.local(2010, 11, 19, 0, 30).utc }

        it "does not change the day" do
          Time.get(@time).day.should == 19
        end
      end
    end

    context "when the time zone is defined as something other than UTC" do
      before do
        Mongoid::Config.instance.time_zone = "Alaska"
        Time.zone = "Stockholm"
      end

      context "when the local time is not observing daylight saving" do
        before { @time = Time.utc(2010, 11, 19) }

        it "returns Alaskan Time" do
          Time.get(@time).utc_offset.should == ActiveSupport::TimeZone["Alaska"].utc_offset
        end
      end

      context "when the local time is observing daylight saving" do
        before do
          @time = Time.utc(2010, 9, 19)
        end

        it "returns Alaskan time with daylight savings" do
          Time.get(@time).utc_offset.should == ActiveSupport::TimeZone["Alaska"].utc_offset + 3600
        end
      end

      context "when we have a time close to midnight" do
        before { @time = Time.zone.local(2010, 11, 19, 0, 30).utc }

        it "changes the day since Alaska is a long way behind Stockholm" do
          Time.get(@time).day.should == 18
        end
      end
    end

    context "when the time zone is defined as UTC" do
      before { Mongoid::Config.instance.time_zone = "UTC" }
      after { Mongoid::Config.instance.time_zone = nil }

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

  describe "round trip - set then get" do
    context "when the time zone is not defined" do
      before do
        Mongoid::Config.instance.time_zone = nil
        Time.zone = "Stockholm"
      end

      context "when the local time is not observing daylight saving" do
        before { @time = Time.set(Time.zone.local(2010, 11, 19)) }

        it "returns the local time" do
          Time.get(@time).utc_offset.should == Time.zone.utc_offset
        end
      end

      context "when the local time is observing daylight saving" do
        before { @time = Time.set(Time.zone.local(2010, 9, 19)) }

        it "returns the local time" do
          Time.get(@time).utc_offset.should == Time.zone.utc_offset + 3600
        end
      end

      context "when we have a time close to midnight" do
        before { @time = Time.set(Time.zone.local(2010, 11, 19, 0, 30)) }

        it "does not change the day" do
          Time.get(@time).day.should == 19
        end
      end
    end

    context "when the time zone is defined as something other than UTC" do
      before do
        Mongoid::Config.instance.time_zone = "Alaska"
        Time.zone = "Stockholm"
      end

      context "when the local time is not observing daylight saving" do
        before { @time = Time.set(Time.zone.local(2010, 11, 19)) }

        it "returns Alaskan Time" do
          Time.get(@time).utc_offset.should == ActiveSupport::TimeZone["Alaska"].utc_offset
        end
      end

      context "when the local time is observing daylight saving" do
        before do
          @time = Time.set(Time.zone.local(2010, 9, 19))
        end

        it "returns Alaskan time with daylight savings" do
          Time.get(@time).utc_offset.should == ActiveSupport::TimeZone["Alaska"].utc_offset + 3600
        end
      end

      context "when we have a time close to midnight" do
        before { @time = Time.set(Time.zone.local(2010, 11, 19, 0, 30)) }

        it "changes the day since Alaska is a long way behind Stockholm" do
          Time.get(@time).day.should == 18
        end
      end
    end
  end
end