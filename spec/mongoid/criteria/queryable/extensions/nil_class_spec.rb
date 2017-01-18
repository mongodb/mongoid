require "spec_helper"

describe NilClass do

  describe "#__add__" do

    it "returns the object" do
      expect(nil.__add__(1)).to eq(1)
    end
  end

  describe "#__evolve_date__" do

    it "returns nil" do
      expect(nil.__evolve_date__).to be_nil
    end
  end

  describe "#__evolve_time__" do

    it "returns nil" do
      expect(nil.__evolve_time__).to be_nil
    end
  end

  describe "#__intersect__" do

    context "when provided a non enumerable" do

      it "returns the object" do
        expect(nil.__intersect__(1)).to eq(1)
      end
    end

    context "when provided an array" do

      it "returns the array" do
        expect(nil.__intersect__([ 1, 2 ])).to eq([ 1, 2 ])
      end
    end

    context "when provided a hash" do

      it "returns the hash" do
        expect(nil.__intersect__({ "$in" => [ 1, 2 ] })).to eq(
          { "$in" => [ 1, 2 ] }
        )
      end
    end
  end

  describe "#__union__" do

    context "when provided a non enumerable" do

      it "returns the object" do
        expect(nil.__union__(1)).to eq(1)
      end
    end

    context "when provided an array" do

      it "returns the array" do
        expect(nil.__union__([ 1, 2 ])).to eq([ 1, 2 ])
      end
    end

    context "when provided a hash" do

      it "returns the hash" do
        expect(nil.__union__({ "$in" => [ 1, 2 ] })).to eq(
          { "$in" => [ 1, 2 ] }
        )
      end
    end
  end
end
