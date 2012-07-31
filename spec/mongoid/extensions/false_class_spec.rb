require "spec_helper"

describe Mongoid::Extensions::FalseClass do

  describe "#__sortable__" do

    it "returns 0" do
      false.__sortable__.should eq(0)
    end
  end

  describe "#is_a?" do

    context "when provided a Boolean" do

      it "returns true" do
        false.is_a?(Boolean).should be_true
      end
    end

    context "when provided a FalseClass" do

      it "returns true" do
        false.is_a?(FalseClass).should be_true
      end
    end

    context "when provided a TrueClass" do

      it "returns false" do
        false.is_a?(TrueClass).should be_false
      end
    end

    context "when provided an invalid class" do

      it "returns false" do
        false.is_a?(String).should be_false
      end
    end
  end
end
