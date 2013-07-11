require "spec_helper"

describe Mongoid::Extensions::Range do

  describe "#__find_args__" do

    let(:range) do
      1..3
    end

    it "returns the range as an array" do
      expect(range.__find_args__).to eq([ 1, 2, 3 ])
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
      expect(range).to be_resizable
    end
  end
end
