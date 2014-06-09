require "spec_helper"

describe FalseClass do

  describe "#is_a?" do

    context "when provided a Boolean" do

      it "returns true" do
        false.is_a?(Boolean).should be_truthy
      end
    end

    context "when provided a FalseClass" do

      it "returns true" do
        false.is_a?(FalseClass).should be_truthy
      end
    end

    context "when provided a TrueClass" do

      it "returns false" do
        false.is_a?(TrueClass).should be false
      end
    end

    context "when provided an invalid class" do

      it "returns false" do
        false.is_a?(String).should be false
      end
    end
  end
end
