require "spec_helper"

describe Mongoid::Extensions::Date do

  describe "__mongoize_time__" do

    context "when using active support's time zone" do

      before do
        Mongoid.use_activesupport_time_zone = true
        Time.zone = "Tokyo"
      end

      after do
        Time.zone = nil
      end

      let(:date) do
        Date.new(2010, 1, 1)
      end

      let(:expected) do
        Time.zone.local(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:mongoized) do
        date.__mongoize_time__
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

      let(:date) do
        Date.new(2010, 1, 1)
      end

      let(:expected) do
        Time.local(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:mongoized) do
        date.__mongoize_time__
      end

      it "returns the date as a local time" do
        expect(mongoized).to eq(expected)
      end
    end
  end

  describe ".demongoize" do

    let(:time) do
      Time.utc(2010, 1, 1, 0, 0, 0, 0)
    end

    let(:expected) do
      Date.new(2010, 1, 1)
    end

    it "keeps the date" do
      expect(Date.demongoize(time)).to eq(expected)
    end

    it "converts to a date" do
      expect(Date.demongoize(time)).to be_a(Date)
    end
  end

  describe ".mongoize" do

    context "when provided a date" do

      let(:date) do
        Date.new(2010, 1, 1)
      end

      let(:evolved) do
        Date.mongoize(date)
      end

      let(:expected) do
        Time.utc(2010, 1, 1, 0, 0, 0)
      end

      it "returns the time" do
        expect(evolved).to eq(expected)
      end
    end

    context "when provided a string" do

      context "when the string is a valid date" do

        let(:date) do
          Date.parse("1st Jan 2010")
        end

        let(:evolved) do
          Date.mongoize(date.to_s)
        end

        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        it "returns the string as a time" do
          expect(evolved).to eq(expected)
        end
      end

      context "when the string is empty" do

        let(:evolved) do
          Date.mongoize("")
        end

        it "returns nil" do
          expect(evolved).to be_nil
        end
      end

      context "when the string is an invalid time" do

        let(:epoch) do
          Date.new(1970, 1, 1)
        end

        it "returns epoch" do
          expect(Date.mongoize("time")).to eq(epoch)
        end
      end
    end

    context "when provided a float" do

      let(:time) do
        Time.utc(2010, 1, 1, 1, 0, 0, 0)
      end

      let(:float) do
        time.to_f
      end

      let(:evolved) do
        Date.mongoize(float)
      end

      let(:expected) do
        Time.at(float)
      end

      it "returns the float as a time" do
        expect(evolved).to eq(Time.utc(expected.year, expected.month, expected.day))
      end
    end

    context "when provided an integer" do

      let(:time) do
        Time.utc(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:integer) do
        time.to_i
      end

      let(:evolved) do
        Date.mongoize(integer)
      end

      let(:expected) do
        Time.at(integer)
      end

      it "returns the integer as a time" do
        expect(evolved).to eq(Time.utc(expected.year, expected.month, expected.day))
      end
    end

    context "when provided an array" do

      let(:time) do
        Time.utc(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:array) do
        [ 2010, 1, 1, 0, 0, 0, 0 ]
      end

      let(:evolved) do
        Date.mongoize(array)
      end

      it "returns the array as a time" do
        expect(evolved).to eq(time)
      end
    end

    context "when provided nil" do

      it "returns nil" do
        expect(Date.mongoize(nil)).to be_nil
      end
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2010, 1, 1)
    end

    let(:time) do
      Time.utc(2010, 1, 1, 0, 0, 0, 0)
    end

    it "returns the date as a time at midnight" do
      expect(date.mongoize).to eq(time)
    end
  end
end
