require "spec_helper"

describe Mongoid::Fields::Internal::Time do

  let(:field) do
    described_class.instantiate(:test, :type => Time)
  end

  let!(:time) do
    Time.local(2010, 11, 19)
  end

  describe "#selection" do

    context "when providing a single value" do

      it "converts the value to a utc time" do
        field.selection(time.utc.to_s).should be_within(1).of(time.utc)
      end
    end

    context "when providing a complex criteria" do

      let(:criteria) do
        { "$ne" => "test" }
      end

      it "returns the criteria" do
        field.selection(criteria).should eq(criteria)
      end
    end
  end

  describe "#serialize" do

    context "when given nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end

    context "when string is empty" do

      it "returns nil" do
        field.serialize("").should be_nil
      end
    end

    context "when given a string" do

      context "when the string is a valid time" do

        it "converts to a utc time" do
          field.serialize(time.to_s).utc_offset.should == 0
        end

        it "serializes with time parsing" do
          field.serialize(time.to_s).should eq(Time.parse(time.to_s).utc)
        end

        it "returns a local date from the string" do
          field.serialize(time.to_s).should eq(
            Time.local(time.year, time.month, time.day, time.hour, time.min, time.sec)
          )
        end
      end

      # This is ridiculous - Ruby 1.8.x returns the current time when calling
      # parse with a string that is not the time.
      unless RUBY_VERSION =~ /1.8/

        context "when the string is an invalid time" do

          it "raises an error" do
            expect {
              field.serialize("shitty time")
            }.to raise_error(Mongoid::Errors::InvalidTime)
          end
        end
      end

      context "when using the ActiveSupport time zone" do

        before do
          Mongoid::Config.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid::Config.use_activesupport_time_zone = false
        end

        context "when the local time is not observing daylight saving" do

          it "returns the local time" do
            field.serialize('2010-11-19 5:00:00').should eq(
              Time.utc(2010, 11, 19, 4)
            )
          end
        end

        context "when the local time is observing daylight saving" do

          it "returns the local time" do
            field.serialize('2010-9-19 5:00:00').should eq(
              Time.utc(2010, 9, 19, 3)
            )
          end
        end
      end
    end

    context "when given a DateTime" do

      it "returns a time" do
        field.serialize(time.to_datetime).should eq(
          Time.local(time.year, time.month, time.day, time.hour, time.min, time.sec)
        )
      end

      context "when using the ActiveSupport time zone" do

        let(:datetime) do
          DateTime.new(2010, 11, 19)
        end

        before do
          Mongoid::Config.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid::Config.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          field.serialize(datetime).should eq(
            Time.utc(2010, 11, 18, 23)
          )
        end
      end
    end

    context "when given a Time" do

      it "converts to a utc time" do
        field.serialize(time).utc_offset.should eq(0)
      end

      it "strips miliseconds" do
        field.serialize(Time.now).usec.should eq(0)
      end

      it "returns utc times unchanged" do
        field.serialize(time.utc).should eq(time.utc)
      end

      it "returns the time as utc" do
        field.serialize(time).should eq(time.utc)
      end
    end

    context "when given an ActiveSupport::TimeWithZone" do

      before { time = 1.hour.ago }

      it "converts it to utc" do
        field.serialize(time.in_time_zone("Alaska")).should eq(
          Time.at(time.to_i).utc
        )
      end
    end

    context "when given a Date" do

      let(:date) do
        Date.today
      end

      it "converts to a utc time" do
        field.serialize(date).should == Time.local(date.year, date.month, date.day)
      end

      it "has a zero utc offset" do
        field.serialize(date).utc_offset.should == 0
      end

      context "when using the ActiveSupport time zone" do

        let(:date) do
          Date.new(2010, 11, 19)
        end

        before do
          Mongoid::Config.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid::Config.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          field.serialize(date).should == Time.utc(2010, 11, 18, 23)
        end
      end
    end

    context "when given an array" do

      let(:array) do
        [2010, 11, 19, 00, 24, 49]
      end

      it "returns a time" do
        field.serialize(array).should == Time.local(*array)
      end

      context "when using the ActiveSupport time zone" do

        before do
          Mongoid::Config.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid::Config.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          field.serialize(array).should eq(
            Time.utc(2010, 11, 18, 23, 24, 49)
          )
        end
      end
    end
  end

  describe "#deserialize" do

    context "when the time zone is not defined" do

      before do
        Mongoid::Config.use_utc = false
      end

      context "when the local time is not observing daylight saving" do

        let(:time) do
          Time.utc(2010, 11, 19)
        end

        it "returns the local time" do
          field.deserialize(time).utc_offset.should eq(
            Time.local(2010, 11, 19).utc_offset
          )
        end
      end

      context "when the local time is observing daylight saving" do

        let(:time) do
          Time.utc(2010, 9, 19)
        end

        it "returns the local time" do
          field.deserialize(time).should eq(time.getlocal)
        end
      end

      context "when we have a time close to midnight" do

        let(:time) do
          Time.local(2010, 11, 19, 0, 30).utc
        end

        it "changes it back to the equivalent local time" do
          field.deserialize(time).should eq(time)
        end
      end

      context "when using the ActiveSupport time zone" do

        before do
          Mongoid::Config.use_activesupport_time_zone = true
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid::Config.use_activesupport_time_zone = false
        end

        it "returns an ActiveSupport::TimeWithZone" do
          field.deserialize(time).class.should eq(ActiveSupport::TimeWithZone)
        end

        context "when the local time is not observing daylight saving" do

          let(:new_time) do
            Time.utc(2010, 11, 19, 12)
          end

          it "returns the local time" do
            field.deserialize(new_time).should eq(
              Time.zone.local(2010, 11, 19, 13)
            )
          end
        end

        context "when the local time is observing daylight saving" do

          let(:new_time) do
            Time.utc(2010, 9, 19, 12)
          end

          it "returns the local time" do
            field.deserialize(new_time).should eq(
              Time.zone.local(2010, 9, 19, 14)
            )
          end
        end

        context "when we have a time close to midnight" do

          let(:new_time) do
            Time.utc(2010, 11, 19, 0, 30)
          end

          it "change it back to the equivalent local time" do
            field.deserialize(new_time).should eq(
              Time.zone.local(2010, 11, 19, 1, 30)
            )
          end
        end
      end
    end

    context "when the time zone is defined as UTC" do

      before do
        Mongoid::Config.use_utc = true
      end

      after do
        Mongoid::Config.use_utc = false
      end

      it "returns utc" do
        field.deserialize(time.dup.utc).utc_offset.should eq(0)
      end

      context "when using the ActiveSupport time zone" do

        let(:time) do
          Time.utc(2010, 11, 19, 0, 30)
        end

        before do
          Mongoid::Config.use_activesupport_time_zone = true
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid::Config.use_activesupport_time_zone = false
        end

        it "returns utc" do
          field.deserialize(time).should eq(
            ActiveSupport::TimeZone['UTC'].local(2010, 11, 19, 0, 30)
          )
        end

        it "returns an ActiveSupport::TimeWithZone" do
          field.deserialize(time).class.should eq(
            ActiveSupport::TimeWithZone
          )
        end
      end
    end

    context "when time is nil" do

      it "returns nil" do
        field.deserialize(nil).should be_nil
      end
    end
  end

  describe "round trip - set then get" do

    context "when the time zone is not defined" do

      before do
        Mongoid::Config.use_utc = false
      end

      context "when the local time is not observing daylight saving" do

        let(:time) do
          field.serialize(Time.local(2010, 11, 19))
        end

        it "returns the local time" do
          field.deserialize(time).utc_offset.should eq(
            Time.local(2010, 11, 19).utc_offset
          )
        end
      end

      context "when the local time is observing daylight saving" do

        let(:time) do
          field.serialize(Time.local(2010, 9, 19))
        end

        it "returns the local time" do
          field.deserialize(time).utc_offset.should eq(
            Time.local(2010, 9, 19).utc_offset
          )
        end
      end

      context "when we have a time close to midnight" do

        let(:original_time) do
          Time.local(2010, 11, 19, 0, 30)
        end

        let(:restored_time) do
          field.serialize(original_time)
        end

        it "does not change a local time" do
          field.deserialize(restored_time).should eq(original_time)
        end
      end
    end

    context "when the time zone is defined as UTC" do

      before do
        Mongoid::Config.use_utc = true
      end

      after do
        Mongoid::Config.use_utc = false
      end

      context "when the local time is not observing daylight saving" do

        let(:time) do
          field.serialize(Time.local(2010, 11, 19))
        end

        it "returns UTC" do
          field.deserialize(time).utc_offset.should eq(0)
        end
      end

      context "when the local time is observing daylight saving" do

        let(:time) do
          field.serialize(Time.local(2010, 9, 19))
        end

        it "returns UTC" do
          field.deserialize(time).utc_offset.should eq(0)
        end
      end

      context "when we have a time close to midnight" do

        let(:new_time) do
          field.serialize(Time.zone.local(2010, 11, 19, 0, 30))
        end

        before do
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
        end

        it "changes the day since UTC is behind Stockholm" do
          field.deserialize(new_time).day.should == 18
        end
      end
    end
  end
end
