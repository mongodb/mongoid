# frozen_string_literal: true

require "spec_helper"

describe Range do

  describe "#__array__" do

    it "returns the range as an array" do
      expect((1..3).__array__).to eq([ 1, 2, 3 ])
    end
  end

  describe "#__evolve_date__" do

    subject(:evolved) { (min..max).__evolve_date__ }

    context "when the range are dates" do
      let(:min) { Date.new(2010, 1, 1) }
      let(:max) { Date.new(2010, 1, 3) }
      let(:expected_min) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }
      let(:expected_max) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => expected_min, "$lte" => expected_max)
      end
    end

    context "when the range are strings" do
      let(:min) { Date.new(2010, 1, 1).to_s }
      let(:max) { Date.new(2010, 1, 3).to_s }
      let(:expected_min) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }
      let(:expected_max) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => expected_min, "$lte" => expected_max)
      end
    end

    context "when the range is floats" do
      let(:min_time) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }
      let(:max_time) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }
      let(:min) { min_time.to_f }
      let(:max) { max_time.to_f }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => min_time, "$lte" => max_time)
      end
    end

    context "when the range is integers" do
      let(:min_time) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }
      let(:max_time) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }
      let(:min) { min_time.to_i }
      let(:max) { max_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => min_time, "$lte" => max_time)
      end
    end

    context "when the range is not inclusive" do
      subject(:evolved) { (min...max).__evolve_date__ }
      let(:min_time) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }
      let(:max_time) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }
      let(:min) { min_time.to_i }
      let(:max) { max_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => min_time, "$lt" => max_time)
      end
    end

    context "when the range is endless" do
      ruby_version_gte '2.7'

      subject(:evolved) { eval('(min..)').__evolve_date__ }
      let(:min_time) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }
      let(:min) { min_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => min_time)
      end
    end

    context "when the range is beginning-less" do
      ruby_version_gte '2.7'

      subject(:evolved) { eval('(..max)').__evolve_date__ }
      let(:max_time) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }
      let(:max) { max_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$lte" => max_time)
      end
    end

    context "when the range is beginning-less not inclusive" do
      ruby_version_gte '2.7'

      subject(:evolved) { eval('(...max)').__evolve_date__ }
      let(:max_time) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }
      let(:max) { max_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$lt" => max_time)
      end
    end
  end

  describe "#__evolve_time__" do

    subject(:evolved) do
      (min..max).__evolve_time__
    end

    context "when the range are dates" do
      let(:min) { Time.new(2010, 1, 1, 12, 0, 0) }
      let(:max) { Time.new(2010, 1, 3, 12, 0, 0) }
      let(:expected_min) { Time.new(2010, 1, 1, 12, 0, 0).utc }
      let(:expected_max) { Time.new(2010, 1, 3, 12, 0, 0).utc }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => expected_min, "$lte" => expected_max)
      end

      it "returns the times in utc" do
        expect(evolved["$gte"].utc_offset).to eq(0)
      end
    end

    context "when the range are strings" do
      let(:min) { Time.new(2010, 1, 1, 12, 0, 0).to_s }
      let(:max) { Time.new(2010, 1, 3, 12, 0, 0).to_s }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => min.to_time, "$lte" => max.to_time)
      end

      it "returns the times in utc" do
        expect(evolved["$gte"].utc_offset).to eq(0)
      end
    end

    context "when the range is floats" do
      let(:min) { 1331890719.1234 }
      let(:max) { 1332890719.7651 }
      let(:expected_min) { Time.at(min).utc }
      let(:expected_max) { Time.at(max).utc }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => expected_min, "$lte" => expected_max)
      end

      it "returns the times in utc" do
        expect(evolved["$gte"].utc_offset).to eq(0)
      end
    end

    context "when the range is integers" do
      let(:min) { 1331890719 }
      let(:max) { 1332890719 }
      let(:expected_min) { Time.at(min).utc }
      let(:expected_max) { Time.at(max).utc }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => expected_min, "$lte" => expected_max)
      end

      it "returns the times in utc" do
        expect(evolved["$gte"].utc_offset).to eq(0)
      end
    end

    context "when the range is not inclusive" do
      subject(:evolved) { (min...max).__evolve_time__ }
      let(:min_time) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }
      let(:max_time) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }
      let(:min) { min_time.to_i }
      let(:max) { max_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => min_time, "$lt" => max_time)
      end
    end

    context "when the range is endless" do
      ruby_version_gte '2.7'

      subject(:evolved) { eval('(min..)').__evolve_time__ }
      let(:min_time) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }
      let(:min) { min_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$gte" => min_time)
      end
    end

    context "when the range is beginning-less" do
      ruby_version_gte '2.7'

      subject(:evolved) { eval('(..max)').__evolve_time__ }
      let(:max_time) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }
      let(:max) { max_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$lte" => max_time)
      end
    end

    context "when the range is beginning-less not inclusive" do
      ruby_version_gte '2.7'

      subject(:evolved) { eval('(...max)').__evolve_time__ }
      let(:max_time) { Time.utc(2010, 1, 3, 0, 0, 0, 0) }
      let(:max) { max_time.to_i }

      it "returns a selection of times" do
        is_expected.to eq("$lt" => max_time)
      end
    end
  end

  shared_examples_for "evolve_range" do
    context "when provided a range" do

      context "when the range is inclusive" do
        let(:range) { 1..3 }

        it "returns the inclusive range criterion" do
          is_expected.to eq("$gte" => 1, "$lte" => 3)
        end
      end

      context "when the range is not inclusive" do
        let(:range) { 1...3 }

        it "returns the non inclusive range criterion" do
          is_expected.to eq("$gte" => 1, "$lt" => 3)
        end
      end

      context "when the range is endless" do
        ruby_version_gte '2.7'

        let(:range) { eval('1..') }

        it "returns the endless range criterion" do
          is_expected.to eq("$gte" => 1)
        end
      end

      context "when the range is endless not inclusive" do
        ruby_version_gte '2.7'

        let(:range) { eval('1...') }

        it "returns the endless range criterion" do
          is_expected.to eq("$gte" => 1)
        end
      end

      context "when the range is beginning-less" do
        ruby_version_gte '2.7'

        let(:range) { eval('..1') }

        it "returns the endless range criterion" do
          is_expected.to eq("$lte" => 1)
        end
      end

      context "when the range is beginning-less not inclusive" do
        ruby_version_gte '2.7'

        let(:range) { eval('...1') }

        it "returns the endless range criterion" do
          is_expected.to eq("$lt" => 1)
        end
      end

      context "when the range is characters" do
        let(:range) { "a".."z" }

        it "returns the character range" do
          is_expected.to eq("$gte" => "a", "$lte" => "z")
        end
      end
    end

    context "when provided Float objects" do
      let(:range) { 1.3..4.5 }

      it "returns the range as Time objects" do
        is_expected.to eq("$gte" => 1.3, "$lte" => 4.5)
      end
    end

    context "when provided Date objects" do
      let(:range) { Date.new(2010, 1, 1)..Date.new(2010, 1, 3) }

      it "returns the range as Time objects" do
        is_expected.to eq({ "$gte" => Time.utc(2010, 1, 1, 0, 0, 0, 0), "$lte" => Time.utc(2010, 1, 3, 0, 0, 0, 0) })
        expect(subject["$gte"].utc?).to be(true)
        expect(subject["$lte"].utc?).to be(true)
      end
    end

    context "when provided Time objects" do
      let(:range) { Time.at(0)..Time.at(1) }

      it "returns the range as Time objects" do
        is_expected.to eq({ "$gte" => Time.at(0), "$lte" => Time.at(1) })
        expect(subject["$gte"].utc?).to be(true)
        expect(subject["$lte"].utc?).to be(true)
      end
    end

    context "when provided ActiveSupport::TimeWithZone objects" do
      let(:range) { Time.at(0).in_time_zone..Time.at(1).in_time_zone }

      it "returns the range as Time objects" do
        is_expected.to eq({ "$gte" => Time.at(0), "$lte" => Time.at(1) })
        expect(subject["$gte"].utc?).to be(true)
        expect(subject["$lte"].utc?).to be(true)
      end
    end

    context "when provided Date objects" do
      let(:range) { Date.new(2010, 1, 1)..Date.new(2010, 1, 3) }

      it "returns the range as Time objects" do
        is_expected.to eq({ "$gte" => Time.utc(2010, 1, 1, 0, 0, 0, 0), "$lte" => Time.utc(2010, 1, 3, 0, 0, 0, 0) })
        expect(subject["$gte"].utc?).to be(true)
        expect(subject["$lte"].utc?).to be(true)
      end
    end

    context "when provided mixed Time and Date objects" do
      let(:range) { Time.at(0)..Date.new(2010, 1, 3) }

      it "returns the range as Time objects" do
        is_expected.to eq({ "$gte" => Time.at(0), "$lte" => Time.utc(2010, 1, 3, 0, 0, 0, 0) })
        expect(subject["$gte"].utc?).to be(true)
        expect(subject["$lte"].utc?).to be(true)
      end
    end

    context "when provided mixed Date and Time objects" do
      let(:range) { Time.at(0).in_time_zone..Time.at(1).in_time_zone }

      it "returns the range as Time objects" do
        is_expected.to eq({ "$gte" => Time.at(0), "$lte" => Time.at(1) })
        expect(subject["$gte"].utc?).to be(true)
        expect(subject["$lte"].utc?).to be(true)
      end
    end
  end

  describe "#__evolve_range__" do
    subject { range.__evolve_range__ }
    it_behaves_like 'evolve_range'
  end

  describe ".evolve" do
    subject { described_class.evolve(range) }
    it_behaves_like 'evolve_range'
  end
end
