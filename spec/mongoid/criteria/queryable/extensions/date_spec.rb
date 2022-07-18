# frozen_string_literal: true

require "spec_helper"

describe Date do

  describe "#__evolve_date__" do

    let(:date) do
      Date.new(2010, 1, 1)
    end

    let(:evolved) do
      date.__evolve_date__
    end

    let(:expected) do
      Time.utc(2010, 1, 1, 0, 0, 0)
    end

    it "returns the time" do
      expect(evolved).to eq(expected)
    end
  end

  describe "#__evolve_time__" do

    let(:date) do
      Date.new(2010, 1, 1)
    end

    let(:evolved) do
      date.__evolve_time__
    end

    let(:expected) do
      Time.local(2010, 1, 1, 0, 0, 0)
    end

    it "returns the time" do
      expect(evolved).to eq(expected)
    end
  end

  describe ".evolve" do

    context "when provided a date" do

      let(:date) do
        Date.new(2010, 1, 1)
      end

      let(:evolved) do
        described_class.evolve(date)
      end

      let(:expected) do
        Time.utc(2010, 1, 1, 0, 0, 0)
      end

      it "returns the time" do
        expect(evolved).to eq(expected)
      end
    end

    context "when provided an array" do

      context "when the array is composed of dates" do

        let(:date) do
          Date.new(2010, 1, 1)
        end

        let(:evolved) do
          described_class.evolve([ date ])
        end

        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        it "returns the array with evolved times" do
          expect(evolved).to eq([ expected ])
        end
      end

      context "when the array is composed of strings" do

        let(:date) do
          Date.parse("1st Jan 2010")
        end

        let(:evolved) do
          described_class.evolve([ date.to_s ])
        end

        it "returns the strings as a times" do
          expect(evolved).to eq([ Time.new(2010, 1, 1, 0, 0, 0, 0).utc ])
        end
      end

      context "when the array is composed of integers" do

        let(:time) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        let(:integer) do
          time.to_i
        end

        let(:evolved) do
          described_class.evolve([ integer ])
        end

        let(:expected) do
          Time.at(integer)
        end

        it "returns the integers as times" do
          expect(evolved).to eq([ time ])
        end
      end

      context "when the array is composed of floats" do

        let(:time) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        let(:float) do
          time.to_f
        end

        let(:evolved) do
          described_class.evolve([ float ])
        end

        let(:expected) do
          Time.at(float)
        end

        it "returns the floats as times" do
          expect(evolved).to eq([ time ])
        end
      end
    end

    context "when provided a range" do

      context "when the range are dates" do

        let(:min) do
          Date.new(2010, 1, 1)
        end

        let(:max) do
          Date.new(2010, 1, 3)
        end

        let(:evolved) do
          described_class.evolve(min..max)
        end

        let(:expected_min) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        let(:expected_max) do
          Time.utc(2010, 1, 3, 0, 0, 0, 0)
        end

        it "returns a selection of times" do
          expect(evolved).to eq(
            { "$gte" => expected_min, "$lte" => expected_max }
          )
        end
      end

      context "when the range are strings" do

        let(:min) do
          Date.new(2010, 1, 1)
        end

        let(:max) do
          Date.new(2010, 1, 3)
        end

        let(:evolved) do
          described_class.evolve(min.to_s..max.to_s)
        end

        let(:expected_min) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        let(:expected_max) do
          Time.utc(2010, 1, 3, 0, 0, 0, 0)
        end

        it "returns a selection of times" do
          expect(evolved).to eq(
            { "$gte" => expected_min, "$lte" => expected_max }
          )
        end
      end

      context "when the range is floats" do

        let(:min_time) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        let(:max_time) do
          Time.utc(2010, 1, 3, 0, 0, 0, 0)
        end

        let(:min) do
          min_time.to_f
        end

        let(:max) do
          max_time.to_f
        end

        let(:evolved) do
          described_class.evolve(min..max)
        end

        it "returns a selection of times" do
          expect(evolved).to eq(
            { "$gte" => min_time, "$lte" => max_time }
          )
        end
      end

      context "when the range is integers" do

        let(:min_time) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        let(:max_time) do
          Time.utc(2010, 1, 3, 0, 0, 0, 0)
        end

        let(:min) do
          min_time.to_i
        end

        let(:max) do
          max_time.to_i
        end

        let(:evolved) do
          described_class.evolve(min..max)
        end

        it "returns a selection of times" do
          expect(evolved).to eq(
            { "$gte" => min_time, "$lte" => max_time }
          )
        end
      end
    end

    context "when provided a string" do

      let(:date) do
        Date.parse("1st Jan 2010")
      end

      let(:evolved) do
        described_class.evolve(date.to_s)
      end

      let(:expected) do
        Time.utc(2010, 1, 1, 0, 0, 0, 0)
      end

      it "returns the string as a time" do
        expect(evolved).to eq(expected)
      end
    end

    context "when provided a float" do

      let(:time) do
        Time.utc(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:float) do
        time.to_f
      end

      let(:evolved) do
        described_class.evolve(float)
      end

      it "returns the float as a time" do
        expect(evolved).to eq(time)
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
        described_class.evolve(integer)
      end

      it "returns the integer as a time" do
        expect(evolved).to eq(time)
      end
    end

    context "when provided an invalid string" do

      let(:evolved) do
        described_class.evolve("bogus")
      end

      it "returns that string" do
        expect(evolved).to eq("bogus")
      end
    end

    context "when provided nil" do

      it "returns nil" do
        expect(described_class.evolve(nil)).to be_nil
      end
    end
  end
end
