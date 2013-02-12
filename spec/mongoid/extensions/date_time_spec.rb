require "spec_helper"

describe Mongoid::Extensions::DateTime do

  describe "__mongoize_time__" do

    context "when the date time has more than seconds precision" do

      let(:date_time) do
        DateTime.parse("2012-06-17 18:42:15.123Z")
      end

      let(:mongoized) do
        date_time.__mongoize_time__
      end

      it "does not drop the precision" do
        mongoized.to_f.to_s.should match(/\.123/)
      end
    end

    context "when using active support's time zone" do

      before do
        Mongoid.use_activesupport_time_zone = true
        Time.zone = "Tokyo"
      end

      after do
        Time.zone = nil
      end

      let(:date_time) do
        DateTime.new(2010, 1, 1)
      end

      let(:expected) do
        Time.zone.local(2010, 1, 1, 9, 0, 0, 0)
      end

      let(:mongoized) do
        date_time.__mongoize_time__
      end

      it "returns the date as a local time" do
        mongoized.should eq(expected)
      end
    end

    context "when not using active support's time zone" do

      before do
        Mongoid.use_activesupport_time_zone = false
      end

      after do
        Mongoid.use_activesupport_time_zone = true
        Time.zone = nil
      end

      let(:date_time) do
        DateTime.new(2010, 1, 1)
      end

      let(:expected) do
        Time.utc(2010, 1, 1, 0, 0, 0, 0).getlocal
      end

      let(:mongoized) do
        date_time.__mongoize_time__
      end

      it "returns the date as a utc time" do
        mongoized.should eq(expected)
      end
    end
  end

  describe ".demongoize" do

    let!(:time) do
      Time.now.utc
    end

    let(:date_time) do
      DateTime.demongoize(time)
    end

    it "converts to a datetime" do
      date_time.should be_kind_of(DateTime)
    end

    it "does not change the time" do
      DateTime.demongoize(time).should eq(time)
    end

    context "when using utc" do

      before do
        Mongoid.use_utc = true
      end

      after do
        Mongoid.use_utc = false
      end

      context "when setting a utc time" do

        let(:user) do
          User.new
        end

        let(:date) do
          DateTime.parse("2012-01-23 08:26:14 PM")
        end

        before do
          user.last_login = date
        end

        it "does not return the time with time zone applied" do
          user.last_login.should eq(date)
        end
      end
    end
  end

  describe ".mongoize" do

    context "when the string is an invalid time" do

      let(:epoch) do
        Time.utc(1970, 1, 1, 0, 0, 0, 0)
      end

      it "returns epoch" do
        DateTime.mongoize("time").should eq(epoch)
      end
    end
  end

  describe "#mongoize" do

    let!(:date_time) do
      Time.now.utc.to_datetime
    end

    context "when the string is an invalid time" do

      it "returns the date time as a time" do
        date_time.mongoize.should be_a(Time)
      end
    end
  end
end
