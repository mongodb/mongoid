require "spec_helper"

describe TrueClass do

  describe "#is_a?" do

    context "when provided a Boolean" do

      it "returns true" do
        true.is_a?(Boolean).should be_true
      end
    end

    context "when provided a FalseClass" do

      it "returns false" do
        true.is_a?(FalseClass).should be_false
      end
    end

    context "when provided a TrueClass" do

      it "returns true" do
        true.is_a?(TrueClass).should be_true
      end
    end

    context "when provided an invalid class" do

      it "returns false" do
        false.is_a?(String).should be_false
      end
    end
  end
end
