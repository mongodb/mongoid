require "spec_helper"

describe Range do
  using Mongoid::Refinements

  describe "#as_find_arguments" do

    let(:range) do
      1..3
    end

    it "returns the range as an array" do
      expect(range.as_find_arguments).to eq([ 1, 2, 3 ])
    end
  end

  describe ".demongoize" do

    context "when the range is ascending" do

      let(:hash) do
        { "min" => 1, "max" => 3 }
      end

      it "returns an ascending range" do
        expect(Range.demongoize(hash)).to eq(1..3)
      end
    end

    context "when the range is ascending with exclude end" do

      let(:hash) do
        { "min" => 1, "max" => 3, "exclude_end" => true }
      end

      it "returns an ascending range" do
        expect(Range.demongoize(hash)).to eq(1...3)
      end
    end

    context "when the range is descending" do

      let(:hash) do
        { "min" => 5, "max" => 1 }
      end

      it "returns an descending range" do
        expect(Range.demongoize(hash)).to eq(5..1)
      end
    end

    context "when the range is descending with exclude end" do

      let(:hash) do
        { "min" => 5, "max" => 1, "exclude_end" => true }
      end

      it "returns an descending range" do
        expect(Range.demongoize(hash)).to eq(5...1)
      end
    end

    context "when the range is letters" do

      let(:hash) do
        { "min" => "a", "max" => "z" }
      end

      it "returns an alphabetic range" do
        expect(Range.demongoize(hash)).to eq("a".."z")
      end
    end

    context "when the range is letters with exclude end" do

      let(:hash) do
        { "min" => "a", "max" => "z", "exclude_end" => true }
      end

      it "returns an alphabetic range" do
        expect(Range.demongoize(hash)).to eq("a"..."z")
      end
    end
  end

  describe ".mongoize" do

    context "when the value is not nil" do

      it "returns the object hash" do
        expect(Range.mongoize(1..3)).to eq({ "min" => 1, "max" => 3 })
      end

      it "returns the object hash when passed an inverse range" do
        expect(Range.mongoize(5..1)).to eq({ "min" => 5, "max" => 1 })
      end

      it "returns the object hash when passed a letter range" do
        expect(Range.mongoize("a".."z")).to eq({ "min" => "a", "max" => "z" })
      end
    end

    context "when the value is not nil with exclude end" do

      it "returns the object hash" do
        expect(Range.mongoize(1...3)).to eq({ "min" => 1, "max" => 3, "exclude_end" => true })
      end

      it "returns the object hash when passed an inverse range" do
        expect(Range.mongoize(5...1)).to eq({ "min" => 5, "max" => 1, "exclude_end" => true })
      end

      it "returns the object hash when passed a letter range" do
        expect(Range.mongoize("a"..."z")).to eq({ "min" => "a", "max" => "z", "exclude_end" => true })
      end

    end

    context "when the value is nil" do

      it "returns nil" do
        expect(Range.mongoize(nil)).to be_nil
      end
    end
  end

  describe "#mongoize" do

    context "when the value is not nil" do

      it "returns the object hash" do
        expect((1..3).mongoize).to eq({ "min" => 1, "max" => 3 })
      end

      it "returns the object hash when passed an inverse range" do
        expect((5..1).mongoize).to eq({ "min" => 5, "max" => 1 })
      end

      it "returns the object hash when passed a letter range" do
        expect(("a".."z").mongoize).to eq({ "min" => "a", "max" => "z" })
      end
    end
  end

  describe "#resizable?" do

    let(:range) do
      1...3
    end

    it "returns true" do
      expect(range.resizable?).to be true
    end
  end

  describe "#__array__" do

    it "returns the range as an array" do
      expect((1..3).__array__).to eq([ 1, 2, 3 ])
    end
  end

  describe "#__evolve_date__" do

    context "when the range are dates" do

      let(:min) do
        Date.new(2010, 1, 1)
      end

      let(:max) do
        Date.new(2010, 1, 3)
      end

      let(:evolved) do
        (min..max).__evolve_date__
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
        (min.to_s..max.to_s).__evolve_date__
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
        (min..max).__evolve_date__
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
        (min..max).__evolve_date__
      end

      it "returns a selection of times" do
        expect(evolved).to eq(
                               { "$gte" => min_time, "$lte" => max_time }
                           )
      end
    end
  end

  describe "#__evolve_time__" do

    context "when the range are dates" do

      let(:min) do
        Time.new(2010, 1, 1, 12, 0, 0)
      end

      let(:max) do
        Time.new(2010, 1, 3, 12, 0, 0)
      end

      let(:evolved) do
        (min..max).__evolve_time__
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
        (min.to_s..max.to_s).__evolve_time__
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
        (min..max).__evolve_time__
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
        (min..max).__evolve_time__
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

  describe ".evolve" do

    context "when provided a range" do

      context "when the range is inclusive" do

        let(:range) do
          1..3
        end

        it "returns the inclusize range criterion" do
          expect(described_class.evolve(range)).to eq(
                                                       { "$gte" => 1, "$lte" => 3 }
                                                   )
        end
      end

      context "when the range is not inclusve" do

        let(:range) do
          1...3
        end

        it "returns the non inclusive range criterion" do
          expect(described_class.evolve(range)).to eq(
                                                       { "$gte" => 1, "$lte" => 2 }
                                                   )
        end
      end

      context "when the range is characters" do

        let(:range) do
          "a".."z"
        end

        it "returns the character range" do
          expect(described_class.evolve(range)).to eq(
                                                       { "$gte" => "a", "$lte" => "z" }
                                                   )
        end
      end
    end

    context "when provided a string" do

      it "returns the string" do
        expect(described_class.evolve("testing")).to eq("testing")
      end
    end
  end
end
