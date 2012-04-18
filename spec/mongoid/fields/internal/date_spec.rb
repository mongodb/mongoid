require "spec_helper"

describe Mongoid::Fields::Internal::Date do

  let(:field) do
    described_class.instantiate(:test, type: Date)
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
          type: Date,
          default: ->{ 1.day.ago }
        )
      end

      it "serializes the result of the call" do
        field.eval_default(nil).should be_a(Time)
      end
    end
  end

  describe "#deserialize" do

    let(:time) do
      Time.now.utc
    end

    it "converts the time back to a date" do
      field.deserialize(time).should be_a_kind_of(Date)
    end

    context "when the time zone is not defined" do

      before do
        Mongoid::Config.use_utc = false
      end

      context "when the local time is not observing daylight saving" do

        let(:time) do
          Time.utc(2010, 11, 19)
        end

        it "returns the same day" do
          field.deserialize(time).day.should eq(19)
        end
      end

      context "when the local time is observing daylight saving" do

        let(:time) do
          Time.utc(2010, 9, 19)
        end

        it "returns the same day" do
          field.deserialize(time).day.should eq(19)
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

      it "returns the same day" do
         field.deserialize(time.dup.utc).day.should eq(time.day)
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

    context "when the string is an invalid time" do

      it "raises an error" do
        expect {
          field.serialize("shitty time")
        }.to raise_error(Mongoid::Errors::InvalidTime)
      end
    end

    context "when given a string" do

      it "converts to a utc time" do
        field.serialize(time.to_s).utc_offset.should eq(0)
      end

      it "returns the right day" do
        field.serialize(time.to_s).day.should eq(time.day)
      end

      it "returns a utc date from the string" do
        field.serialize(time.to_s).should eq(Time.utc(time.year, time.month, time.day))
      end
    end

    context "when given a DateTime" do

      it "returns a time" do
        field.serialize(time.to_datetime).should eq(Time.utc(time.year, time.month, time.day))
      end
    end

    context "when given a Time" do

      it "converts to a utc time" do
        field.serialize(time).utc_offset.should eq(0)
      end

      it "strips miliseconds" do
        field.serialize(Time.now).usec.should eq(0)
      end

      it "returns utc times the same day, but at midnight" do
        field.serialize(time.utc).should eq(Time.utc(time.utc.year, time.utc.month, time.utc.day))
      end

      it "returns the date for the time" do
        field.serialize(time).should eq(Time.utc(time.year, time.month, time.day))
      end
    end

    context "when given an ActiveSupport::TimeWithZone" do

      let(:new_time) do
        time.in_time_zone("Canberra")
      end

      it "converts it to utc" do
        field.serialize(new_time).should eq(Time.utc(new_time.year, new_time.month, new_time.day))
      end
    end

    context "when given a Date" do

      let(:date) do
        Date.today
      end

      it "converts to a utc time" do
        field.serialize(date).should eq(Time.utc(date.year, date.month, date.day))
      end
    end

    context "when given an Array" do

      let(:array) do
        [ time.year, time.month, time.day ]
      end

      it "converts to a utc time" do
        field.serialize(array).should eq(Time.utc(*array))
        field.serialize(array).utc_offset.should eq(0)
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
          field.serialize(Time.zone.local(2010, 11, 19, 0, 30))
        end

        it "does not change the day" do
          field.deserialize(time).day.should eq(19)
        end
      end

      context "when the local time is observing daylight saving" do

        before do
          field.serialize(Time.zone.local(2010, 9, 19, 0, 30))
        end

        it "does not change the day" do
          field.deserialize(time).day.should eq(19)
        end
      end
    end
  end
end
