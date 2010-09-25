require "spec_helper"

describe Mongoid::Extensions::TimeConversions do
  before { @time = Time.local(2010, 11, 19) }

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

      it "uses Time.parse - note that this returns the wrong day due sometimes since it ignores the time zone" do
        Time.set(@time.to_s).should == Time.parse(@time.to_s).utc
      end

      it "returns a local date from the string due to a limitation in Time.parse" do
        Time.set(@time.to_s).should == Time.local(@time.year, @time.month, @time.day, @time.hour, @time.min, @time.sec)
      end

      context "when using the ActiveSupport time zone" do
        before do
          Mongoid::Config.instance.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end
        after do
          Time.zone = nil
          Mongoid::Config.instance.use_activesupport_time_zone = false
        end

        context "when the local time is not observing daylight saving" do
          it "returns the local time" do
            Time.set('2010-11-19 5:00:00').should == Time.utc(2010, 11, 19, 4)
          end
        end

        context "when the local time is observing daylight saving" do
          it "returns the local time" do
            Time.set('2010-9-19 5:00:00').should == Time.utc(2010, 9, 19, 3)
          end
        end
      end
    end

    context "when given a DateTime" do
      it "returns a time" do
        Time.set(@time.to_datetime).should == Time.local(@time.year, @time.month, @time.day, @time.hour, @time.min, @time.sec)
      end

      context "when using the ActiveSupport time zone" do
        before do
          Mongoid::Config.instance.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
          @datetime = DateTime.new(2010, 11, 19)
        end
        after do
          Time.zone = nil
          Mongoid::Config.instance.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          Time.set(@datetime).should == Time.utc(2010, 11, 18, 23)
        end
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
        Time.set(@date).should == Time.local(@date.year, @date.month, @date.day)
        Time.set(@date).utc_offset.should == 0
      end

      context "when using the ActiveSupport time zone" do
        before do
          Mongoid::Config.instance.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
          @date = Date.new(2010, 11, 19)
        end
        after do
          Time.zone = nil
          Mongoid::Config.instance.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          Time.set(@date).should == Time.utc(2010, 11, 18, 23)
        end
      end
    end

    context "when given an array" do
      before { @array = [2010, 11, 19, 00, 24, 49] }

      it "returns a time" do
        Time.set(@array).should == Time.local(*@array)
      end

      context "when using the ActiveSupport time zone" do
        before do
          Mongoid::Config.instance.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end
        after do
          Time.zone = nil
          Mongoid::Config.instance.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          Time.set(@array).should == Time.utc(2010, 11, 18, 23, 24, 49)
        end
      end
    end
  end

  describe ".get" do
    context "when the time zone is not defined" do
      before { Mongoid::Config.instance.use_utc = false }

      context "when the local time is not observing daylight saving" do
        before { @time = Time.utc(2010, 11, 19) }

        it "returns the local time" do
          Time.get(@time).utc_offset.should == Time.local(2010, 11, 19).utc_offset
        end
      end

      context "when the local time is observing daylight saving" do
        before { @time = Time.utc(2010, 9, 19) }

        it "returns the local time" do
          Time.get(@time).should == @time.getlocal
        end
      end

      context "when we have a time close to midnight" do
        before { @time = Time.local(2010, 11, 19, 0, 30).utc }

        it "change it back to the equivalent local time" do
          Time.get(@time).should == @time
        end
      end

      context "when using the ActiveSupport time zone" do
        before do
          Mongoid::Config.instance.use_activesupport_time_zone = true
          Time.zone = "Stockholm"
        end
        after do
          Time.zone = nil
          Mongoid::Config.instance.use_activesupport_time_zone = false
        end

        it "returns an ActiveSupport::TimeWithZone" do
          Time.get(@time).class.should == ActiveSupport::TimeWithZone
        end

        context "when the local time is not observing daylight saving" do
          before { @time = Time.utc(2010, 11, 19, 12) }

          it "returns the local time" do
            Time.get(@time).should == Time.zone.local(2010, 11, 19, 13)
          end
        end

        context "when the local time is observing daylight saving" do
          before { @time = Time.utc(2010, 9, 19, 12) }

          it "returns the local time" do
            Time.get(@time).should == Time.zone.local(2010, 9, 19, 14)
          end
        end

        context "when we have a time close to midnight" do
          before { @time = Time.utc(2010, 11, 19, 0, 30) }

          it "change it back to the equivalent local time" do
            Time.get(@time).should == Time.zone.local(2010, 11, 19, 1, 30)
          end
        end
      end
    end

    context "when the time zone is defined as UTC" do
      before { Mongoid::Config.instance.use_utc = true }
      after { Mongoid::Config.instance.use_utc = false }

      it "returns utc" do
        Time.get(@time.dup.utc).utc_offset.should == 0
      end

      context "when using the ActiveSupport time zone" do
        before do
          Mongoid::Config.instance.use_activesupport_time_zone = true
          Time.zone = "Stockholm"
          @time = Time.utc(2010, 11, 19, 0, 30)
        end
        after do
          Time.zone = nil
          Mongoid::Config.instance.use_activesupport_time_zone = false
        end

        it "returns utc" do
          Time.get(@time).should == ActiveSupport::TimeZone['UTC'].local(2010, 11, 19, 0, 30)
        end

        it "returns an ActiveSupport::TimeWithZone" do
          Time.get(@time).class.should == ActiveSupport::TimeWithZone
        end
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
      before { Mongoid::Config.instance.use_utc = false }

      context "when the local time is not observing daylight saving" do
        before { @time = Time.set(Time.local(2010, 11, 19)) }

        it "returns the local time" do
          Time.get(@time).utc_offset.should == Time.local(2010, 11, 19).utc_offset
        end
      end

      context "when the local time is observing daylight saving" do
        before { @time = Time.set(Time.local(2010, 9, 19)) }

        it "returns the local time" do
          Time.get(@time).utc_offset.should == Time.local(2010, 9, 19).utc_offset
        end
      end

      context "when we have a time close to midnight" do
        before do
          @original_time = Time.local(2010, 11, 19, 0, 30)
          @stored_time = Time.set(@original_time)
        end

        it "does not change a local time" do
          Time.get(@stored_time).should == @original_time
        end
      end
    end

    context "when the time zone is defined as UTC" do
      before { Mongoid::Config.instance.use_utc = true }
      after { Mongoid::Config.instance.use_utc = false }

      context "when the local time is not observing daylight saving" do
        before { @time = Time.set(Time.local(2010, 11, 19)) }

        it "returns UTC" do
          Time.get(@time).utc_offset.should == 0
        end
      end

      context "when the local time is observing daylight saving" do
        before do
          @time = Time.set(Time.local(2010, 9, 19))
        end

        it "returns UTC" do
          Time.get(@time).utc_offset.should == 0
        end
      end

      context "when we have a time close to midnight" do
        before do
          Time.zone = "Stockholm"
          @time = Time.set(Time.zone.local(2010, 11, 19, 0, 30))
        end
        after { Time.zone = nil }

        it "changes the day since UTC is behind Stockholm" do
          Time.get(@time).day.should == 18
        end
      end
    end
  end
end
