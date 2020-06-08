# frozen_string_literal: true
# encoding: utf-8

require "lite_spec_helper"

describe Time do

  describe ".evolve" do

    context "when provided a time" do

      context "when the time is not in utc" do

        let(:time) do
          Time.new(2010, 1, 1, 14, 0, 0, '+02:00')
        end

        let(:evolved) do
          described_class.evolve(time)
        end

        let(:expected) do
          Time.new(2010, 1, 1, 12, 0, 0, '+00:00')
        end

        it "returns the same time" do
          expect(evolved).to eq(expected)
        end

        it 'does not mutate original time' do
          described_class.evolve(time)
          expect(time.utc_offset).to eq(7200)
        end

        it "returns the time in utc" do
          expect(evolved.utc_offset).to eq(0)
        end
      end

      context "when the time is already utc" do

        let(:time) do
          Time.new(2010, 1, 1, 12, 0, 0).utc
        end

        let(:evolved) do
          described_class.evolve(time)
        end

        let(:expected) do
          Time.new(2010, 1, 1, 12, 0, 0).utc
        end

        it "returns the same time" do
          expect(evolved).to eq(expected)
        end

        it "returns the time in utc" do
          expect(evolved.utc_offset).to eq(0)
        end
      end
    end

    context "when provided an array" do

      context "when the array is composed of times" do

        let(:time) do
          Time.new(2010, 1, 1, 12, 0, 0)
        end

        let(:evolved) do
          described_class.evolve([ time ])
        end

        let(:expected) do
          Time.new(2010, 1, 1, 12, 0, 0).utc
        end

        it "returns the array with evolved times" do
          expect(evolved).to eq([ expected ])
        end

        it "returns utc times" do
          expect(evolved.first.utc_offset).to eq(0)
        end
      end

      context "when the array is composed of strings" do

        let(:time) do
          Time.parse("1st Jan 2010 12:00:00+01:00")
        end

        let(:evolved) do
          described_class.evolve([ time.to_s ])
        end

        it "returns the strings as a times" do
          expect(evolved).to eq([ time.to_time ])
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

      context "when the range are times" do

        let(:min) do
          Time.new(2010, 1, 1, 12, 0, 0)
        end

        let(:max) do
          Time.new(2010, 1, 3, 12, 0, 0)
        end

        let(:evolved) do
          described_class.evolve(min..max)
        end

        let(:expected_min) do
          Time.new(2010, 1, 1, 12, 0, 0).utc
        end

        let(:expected_max) do
          Time.new(2010, 1, 3, 12, 0, 0).utc
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
          Time.new(2010, 1, 1, 12, 0, 0)
        end

        let(:max) do
          Time.new(2010, 1, 3, 12, 0, 0)
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

      let(:time) do
        Time.parse("1st Jan 2010 12:00:00+01:00")
      end

      let(:evolved) do
        described_class.evolve(time.to_s)
      end

      it "returns the string as a time" do
        expect(evolved).to eq(time.to_time)
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

  describe "#__evolve_date__" do

    let(:evolved) do
      time.__evolve_date__
    end

    context 'beginning of day' do
      let(:time) do
        Time.new(2010, 1, 1, 0, 0, 1).freeze
      end

      it "returns midnight utc" do
        expect(evolved).to eq(Time.utc(2010, 1, 1, 0, 0, 0))
      end
    end

    context 'end of day' do
      let(:time) do
        Time.new(2010, 1, 1, 23, 59, 59).freeze
      end

      it "returns midnight utc" do
        expect(evolved).to eq(Time.utc(2010, 1, 1, 0, 0, 0))
      end
    end
  end

  describe "#__evolve_time__" do

    let(:time) do
      Time.new(2010, 1, 1, 12, 0, 0).freeze
    end

    let(:evolved) do
      time.__evolve_time__
    end

    it "returns self as utc" do
      expect(evolved).to eq(Time.new(2010, 1, 1, 12, 0, 0).utc)
    end
  end
end
