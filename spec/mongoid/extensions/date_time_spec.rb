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
        expect(mongoized.to_f.to_s).to match(/\.123/)
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
        expect(mongoized).to eq(expected)
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
        expect(mongoized).to eq(expected)
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
      expect(date_time).to be_kind_of(DateTime)
    end

    it "does not change the time" do
      expect(DateTime.demongoize(time)).to eq(time)
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
          expect(user.last_login).to eq(date)
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
        expect(DateTime.mongoize("time")).to eq(epoch)
      end
    end
  end

  describe "#mongoize" do

    let!(:date_time) do
      Time.now.utc.to_datetime
    end

    context "when the string is an invalid time" do

      it "returns the date time as a time" do
        expect(date_time.mongoize).to be_a(Time)
      end
    end
  end
end
