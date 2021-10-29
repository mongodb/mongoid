# frozen_string_literal: true

require "spec_helper"

describe Set do

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
