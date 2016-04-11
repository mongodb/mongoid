require "spec_helper"

describe Set do
  using Mongoid::Refinements

  describe "#demongoize" do

    it "returns the set if Array" do
      expect(Set.demongoize([ "test" ])).to eq(Set.new([ "test" ]))
    end
  end

  describe ".mongoize" do

    it "returns an array" do
      expect(Set.mongoize([ "test" ])).to eq([ "test" ])
    end

    it "returns an array even if the value is a set" do
      expect(Set.mongoize(Set.new([ "test" ]))).to eq([ "test" ])
    end
  end

  describe "#mongoize" do

    let(:set) do
      Set.new([ "test" ])
    end

    it "returns an array" do
      expect(set.mongoize).to eq([ "test" ])
    end
  end

  describe ".evolve" do

    context "when provided a set" do

      let(:set) do
        ::Set.new([ 1, 2, 3 ])
      end

      it "returns an array" do
        expect(described_class.evolve(set)).to eq([ 1, 2, 3 ])
      end
    end

    context "when provided an array" do

      it "returns an array" do
        expect(described_class.evolve([ 1, 2, 3 ])).to eq([ 1, 2, 3 ])
      end
    end

    context "when provided another object" do

      it "returns the object" do
        expect(described_class.evolve("testing")).to eq("testing")
      end
    end

    context "when provided nil" do

      it "returns nil" do
        expect(described_class.evolve(nil)).to be_nil
      end
    end
  end
end
