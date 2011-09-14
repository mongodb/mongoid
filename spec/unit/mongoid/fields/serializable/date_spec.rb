require "spec_helper"

describe Mongoid::Fields::Serializable::Date do

  let(:field) do
    described_class.instantiate(:test, :type => Date)
  end

  let!(:time) do
    Time.local(2010, 11, 19)
  end

  describe "#cast_on_read?" do

    it "returns true" do
      field.should be_cast_on_read
    end
  end

  describe "#eval_default" do

    context "when provided a proc" do

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Date,
          :default => lambda { 1.day.ago }
        )
      end

      it "serializes the result of the call" do
        field.eval_default(nil).should be_a(Time)
      end
    end
  end

  describe "#deserialize" do

    let(:time) { Time.now.utc }

    it "converts the time back to a date" do
      field.deserialize(time).should be_a_kind_of(Date)
    end

    context "when the time zone is not defined" do

      before do
        Mongoid::Config.use_utc = false
      end

      context "when the local time is not observing daylight saving" do

        let(:time) { Time.utc(2010, 11, 19) }

        it "returns the same day" do
          field.deserialize(time).day.should == 19
        end
      end

      context "when the local time is observing daylight saving" do

        let(:time) { Time.utc(2010, 9, 19) }

        it "returns the same day" do
          field.deserialize(time).day.should == 19
        end
      end
    end

    context "when the time zone is defined as UTC" do

      before { Mongoid::Config.use_utc = true }

      after { Mongoid::Config.use_utc = false }

      it "returns the same day" do
         field.deserialize(time.dup.utc).day.should == time.day
      end
    end

    context "when time is nil" do

      it "returns nil" do
        field.deserialize(nil).should be_nil
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

      it "converts to a utc time" do
        field.serialize(time.to_s).utc_offset.should == 0
      end

      it "returns the right day" do
        field.serialize(time.to_s).day.should == time.day
      end

      it "returns a utc date from the string" do
        field.serialize(time.to_s).should == Time.utc(time.year, time.month, time.day)
      end
    end

    context "when given a DateTime" do

      it "returns a time" do
        field.serialize(time.to_datetime).should == Time.utc(time.year, time.month, time.day)
      end
    end

    context "when given a Time" do

      it "converts to a utc time" do
        field.serialize(time).utc_offset.should == 0
      end

      it "strips miliseconds" do
        field.serialize(Time.now).usec.should == 0
      end

      it "returns utc times the same day, but at midnight" do
        field.serialize(time.utc).should == Time.utc(time.utc.year, time.utc.month, time.utc.day)
      end

      it "returns the date for the time" do
        field.serialize(time).should == Time.utc(time.year, time.month, time.day)
      end
    end

    context "when given an ActiveSupport::TimeWithZone" do

      let(:new_time) { time.in_time_zone("Canberra") }

      it "converts it to utc" do
        field.serialize(new_time).should == Time.utc(new_time.year, new_time.month, new_time.day)
      end
    end

    context "when given a Date" do

      before { @date = Date.today }

      it "converts to a utc time" do
        field.serialize(@date).should == Time.utc(@date.year, @date.month, @date.day)
      end
    end

    context "when given an Array" do

      before { @array = [time.year, time.month, time.day] }

      it "converts to a utc time" do
        field.serialize(@array).should == Time.utc(*@array)
        field.serialize(@array).utc_offset.should == 0
      end
    end
  end

  context "when performing a round trip" do

    context "when the time zone is not defined" do

      before do
        Mongoid::Config.use_utc = false
        Time.zone = "Stockholm"
      end

      after do
        Time.zone = nil
      end

      context "when the local time is not observing daylight saving" do

        before do
          time = field.serialize(Time.zone.local(2010, 11, 19, 0, 30))
        end

        it "does not change the day" do
          field.deserialize(time).day.should == 19
        end
      end

      context "when the local time is observing daylight saving" do

        before do
          time = field.serialize(Time.zone.local(2010, 9, 19, 0, 30))
        end

        it "does not change the day" do
          field.deserialize(time).day.should == 19
        end
      end
    end
  end
end
