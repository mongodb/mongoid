require "spec_helper"

describe Mongoid::Refinements::Extension do
  using Mongoid::Refinements::Extension

  describe ".demongoize" do

    context "when the object is not a symbol" do

      it "returns the symbol" do
        expect(Symbol.demongoize("test")).to eq(:test)
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        expect(Symbol.demongoize(nil)).to be_nil
      end
    end
  end

  describe ".mongoize" do

    context "when the object is not a symbol" do

      it "returns the symbol" do
        expect(Symbol.mongoize("test")).to eq(:test)
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        expect(Symbol.mongoize(nil)).to be_nil
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(:test.mongoize).to eq(:test)
    end
  end
end
