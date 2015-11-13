require "spec_helper"

describe Mongoid::Refinements::Extension do
  using Mongoid::Refinements::Extension

  describe "#sortable" do

    it "returns 1" do
      expect(true.sortable).to eq(1)
    end
  end

  describe "#is_a?" do

    context "when provided a Boolean" do

      it "returns true" do
        expect(true.is_a?(Boolean)).to be true
      end
    end

    context "when provided a FalseClass" do

      it "returns false" do
        expect(true.is_a?(FalseClass)).to be false
      end
    end

    context "when provided a TrueClass" do

      it "returns true" do
        expect(true.is_a?(TrueClass)).to be true
      end
    end

    context "when provided an invalid class" do

      it "returns false" do
        expect(false.is_a?(String)).to be false
      end
    end
  end
end
