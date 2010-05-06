require "spec_helper"

describe Mongoid::Extensions::DateTime::Conversions do

  before do
    Mongoid::Config.instance.time_zone = nil
    Time.zone = "Eastern Time (US & Canada)"
    @time = Time.local(1976, 11, 19)
  end

  after do
    Time.zone = nil
  end

  describe "#set" do

    before do
      @date_time = DateTime.civil(2005, 11, 19).new_offset(1800)
    end

    context "when value is a string" do

      it "converts to a utc time" do
        DateTime.set(@date_time.to_s).utc_offset.should == 0
      end

    end

    context "when value is a date_time" do

      it "converts to a utc time" do
        DateTime.set(@date_time).utc_offset.should == 0
      end

      it "does not lose time zone or switch day" do
        Time.zone = "Stockholm"
        @date_time = Time.local(1976, 11, 19, 0, 30).to_datetime
        DateTime.set(@date_time).should == Time.utc(@date_time.year, @date_time.month, @date_time.day, @date_time.hour, @date_time.min, @date_time.sec)
      end

    end

    context "when value is nil" do

      it "returns nil" do
        DateTime.set(nil).should be_nil
      end

    end

  end

  describe "#get" do

    context "when no time zone is configured" do

      context "when time is provided" do

        it "returns a DateTime" do
          DateTime.get(@time.dup).should be_a_kind_of(DateTime)
        end

        it "returns the local date_time" do
          DateTime.get(@time.dup).should == Time.local(1976, 11, 19).to_datetime
        end

        it "preserves the utc offset" do
          DateTime.get(@time.dup).utc_offset.should == @time.utc_offset
        end

      end

      context "when Alaska time zone is configured" do

        before do
          Mongoid::Config.instance.time_zone = "Alaska"
        end

        after do
          Mongoid::Config.instance.time_zone = nil
        end

        it "returns a DateTime" do
          DateTime.get(@time.dup).should be_a_kind_of(DateTime)
        end

        it "returns a Alaskan date_time" do
          @time = Time.local(1999, 12, 15) # time in winter when no DST
          DateTime.get(@time.dup).utc_offset.should == ActiveSupport::TimeZone["Alaska"].utc_offset
        end

      end

      context "when time is nil" do

        it "returns nil" do
          DateTime.get(nil).should be_nil
        end

      end

    end

  end
end
