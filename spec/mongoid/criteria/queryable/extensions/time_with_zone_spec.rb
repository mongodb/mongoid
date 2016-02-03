require "spec_helper"

describe ActiveSupport::TimeWithZone do

  let(:time_zone) do
    ActiveSupport::TimeZone.new("Eastern Time (US & Canada)")
  end

  describe ".evolve" do

    context "when provided a time" do

      let(:date) do
        time_zone.local(2010, 1, 1, 12, 0, 0)
      end

      let(:evolved) do
        described_class.evolve(date)
      end

      let(:expected) do
        Time.utc(2010, 1, 1, 17, 0, 0)
      end

      it "returns the same time" do
        expect(evolved).to eq(expected)
      end

      it "returns the time in utc" do
        expect(evolved.utc_offset).to eq(0)
      end
    end

    context "when provided an array" do

      context "when the array is composed of times" do

        let(:date) do
          time_zone.local(2010, 1, 1, 12, 0, 0)
        end

        let(:evolved) do
          described_class.evolve([ date ])
        end

        let(:expected) do
          Time.utc(2010, 1, 1, 17, 0, 0)
        end

        it "returns the array with evolved times" do
          expect(evolved).to eq([ expected ])
        end

        it "returns utc times" do
          expect(evolved.first.utc_offset).to eq(0)
        end
      end

      context "when the array is composed of strings" do

        let(:date) do
          time_zone.parse("1st Jan 2010 12:00:00+01:00")
        end

        let(:evolved) do
          described_class.evolve([ date.to_s ])
        end

        it "returns the strings as a times" do
          expect(evolved).to eq([ date.to_time ])
        end

        it "returns the times in utc" do
          expect(evolved.first.utc_offset).to eq(0)
        end
      end

      context "when the array is composed of integers" do

        let(:integer) do
          1331890719
        end

        let(:evolved) do
          described_class.evolve([ integer ])
        end

        let(:expected) do
          Time.at(integer).utc
        end

        it "returns the integers as times" do
          expect(evolved).to eq([ expected ])
        end

        it "returns the times in utc" do
          expect(evolved.first.utc_offset).to eq(0)
        end
      end

      context "when the array is composed of floats" do

        let(:float) do
          1331890719.413
        end

        let(:evolved) do
          described_class.evolve([ float ])
        end

        let(:expected) do
          Time.at(float).utc
        end

        it "returns the floats as times" do
          expect(evolved).to eq([ expected ])
        end

        it "returns the times in utc" do
          expect(evolved.first.utc_offset).to eq(0)
        end
      end
    end

    context "when provided a range" do

      context "when the range are dates" do

        let(:min) do
          time_zone.local(2010, 1, 1, 12, 0, 0)
        end

        let(:max) do
          time_zone.local(2010, 1, 3, 12, 0, 0)
        end

        let(:evolved) do
          described_class.evolve(min..max)
        end

        let(:expected_min) do
          Time.utc(2010, 1, 1, 17, 0, 0)
        end

        let(:expected_max) do
          Time.utc(2010, 1, 3, 17, 0, 0)
        end

        it "returns a selection of times" do
          expect(evolved).to eq(
            { "$gte" => expected_min, "$lte" => expected_max }
          )
        end

        it "returns the times in utc" do
          expect(evolved["$gte"].utc_offset).to eq(0)
        end
      end

      context "when the range are strings" do

        let(:min) do
          time_zone.local(2010, 1, 1, 12, 0, 0)
        end

        let(:max) do
          time_zone.local(2010, 1, 3, 12, 0, 0)
        end

        let(:evolved) do
          described_class.evolve(min.to_s..max.to_s)
        end

        it "returns a selection of times" do
          expect(evolved).to eq(
            { "$gte" => min.to_time, "$lte" => max.to_time }
          )
        end

        it "returns the times in utc" do
          expect(evolved["$gte"].utc_offset).to eq(0)
        end
      end

      context "when the range is floats" do

        let(:min) do
          1331890719.1234
        end

        let(:max) do
          1332890719.7651
        end

        let(:evolved) do
          described_class.evolve(min..max)
        end

        let(:expected_min) do
          Time.at(min).utc
        end

        let(:expected_max) do
          Time.at(max).utc
        end

        it "returns a selection of times" do
          expect(evolved).to eq(
            { "$gte" => expected_min, "$lte" => expected_max }
          )
        end

        it "returns the times in utc" do
          expect(evolved["$gte"].utc_offset).to eq(0)
        end
      end

      context "when the range is integers" do

        let(:min) do
          1331890719
        end

        let(:max) do
          1332890719
        end

        let(:evolved) do
          described_class.evolve(min..max)
        end

        let(:expected_min) do
          Time.at(min).utc
        end

        let(:expected_max) do
          Time.at(max).utc
        end

        it "returns a selection of times" do
          expect(evolved).to eq(
            { "$gte" => expected_min, "$lte" => expected_max }
          )
        end

        it "returns the times in utc" do
          expect(evolved["$gte"].utc_offset).to eq(0)
        end
      end
    end

    context "when provided a string" do

      let(:date) do
        time_zone.parse("1st Jan 2010 12:00:00+01:00")
      end

      let(:evolved) do
        described_class.evolve(date.to_s)
      end

      it "returns the string as a time" do
        expect(evolved).to eq(date.to_time)
      end

      it "returns the time in utc" do
        expect(evolved.utc_offset).to eq(0)
      end
    end

    context "when provided a float" do

      let(:float) do
        1331890719.8170738
      end

      let(:evolved) do
        described_class.evolve(float)
      end

      let(:expected) do
        Time.at(float)
      end

      it "returns the float as a time" do
        expect(evolved).to eq(expected)
      end

      it "returns the time in utc" do
        expect(evolved.utc_offset).to eq(0)
      end
    end

    context "when provided an integer" do

      let(:integer) do
        1331890719
      end

      let(:evolved) do
        described_class.evolve(integer)
      end

      let(:expected) do
        Time.at(integer)
      end

      it "returns the integer as a time" do
        expect(evolved).to eq(expected)
      end

      it "returns the time in utc" do
        expect(evolved.utc_offset).to eq(0)
      end
    end

    context "when provided nil" do

      it "returns nil" do
        expect(described_class.evolve(nil)).to be_nil
      end
    end
  end

  describe "#__evolve_time__" do

    let(:date) do
      time_zone.local(2010, 1, 1, 12, 0, 0)
    end

    let(:evolved) do
      date.__evolve_time__
    end

    let(:expected) do
      Time.utc(2010, 1, 1, 17, 0, 0)
    end

    it "returns the same time" do
      expect(evolved).to eq(expected)
    end

    it "returns the time in utc" do
      expect(evolved.utc_offset).to eq(0)
    end
  end
end
