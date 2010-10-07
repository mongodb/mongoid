require "spec_helper"

describe Mongoid::Matchers::Default do


  describe "#matches?" do

    let(:matcher) { Mongoid::Matchers::Default.new("Testing") }

    context "when the values are equal" do

      it "returns true" do
        matcher.matches?("Testing").should be_true
      end

    end

    context "when the values are not equal" do

      it "returns false" do
        matcher.matches?("Other").should be_false
      end

    end

  end

  describe "#matches? when comparing a String to an Array attribute" do

    let(:matcher) { Mongoid::Matchers::Default.new(["Test1", "Test2", "Test3"]) }

    context "when the attribute contains the value" do

      it "returns true" do
        matcher.matches?("Test1").should be_true
      end

    end

    context "when the attribute does not contain the value" do

      it "returns false" do
        matcher.matches?("Test4").should be_false
      end

    end

  end

end
