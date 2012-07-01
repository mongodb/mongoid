require "spec_helper"

describe Mongoid::Extensions::Range do

  describe "#__find_args__" do

    let(:range) do
      1..3
    end

    it "returns the range as an array" do
      range.__find_args__.should eq([ 1, 2, 3 ])
    end
  end

  describe ".demongoize" do

    context "when the range is ascending" do

      let(:hash) do
        { "min" => 1, "max" => 3 }
      end

      it "returns an ascending range" do
        Range.demongoize(hash).should eq(1..3)
      end
    end

    context "when the range is descending" do

      let(:hash) do
        { "min" => 5, "max" => 1 }
      end

      it "returns an descending range" do
        Range.demongoize(hash).should eq(5..1)
      end
    end

    context "when the range is letters" do

      let(:hash) do
        { "min" => "a", "max" => "z" }
      end

      it "returns an alphabetic range" do
        Range.demongoize(hash).should eq("a".."z")
      end
    end
  end

  describe ".mongoize" do

    context "when the value is not nil" do

      it "returns the object hash" do
        Range.mongoize(1..3).should eq({ "min" => 1, "max" => 3 })
      end

      it "returns the object hash when passed an inverse range" do
        Range.mongoize(5..1).should eq({ "min" => 5, "max" => 1 })
      end

      it "returns the object hash when passed a letter range" do
        Range.mongoize("a".."z").should eq({ "min" => "a", "max" => "z" })
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        Range.mongoize(nil).should be_nil
      end
    end
  end

  describe "#mongoize" do

    context "when the value is not nil" do

      it "returns the object hash" do
        (1..3).mongoize.should eq({ "min" => 1, "max" => 3 })
      end

      it "returns the object hash when passed an inverse range" do
        (5..1).mongoize.should eq({ "min" => 5, "max" => 1 })
      end

      it "returns the object hash when passed a letter range" do
        ("a".."z").mongoize.should eq({ "min" => "a", "max" => "z" })
      end
    end
  end

  describe "#resizable?" do

    let(:range) do
      1...3
    end

    it "returns true" do
      range.should be_resizable
    end
  end
end
