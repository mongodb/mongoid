require "spec_helper"

describe Mongoid::Matchers::Ne do

  let(:matcher) do
    described_class.new("first")
  end

  describe "#matches?" do

    context "when the values are not equal" do

      it "returns true" do
        matcher.matches?("$ne" => "second").should be_true
      end
    end

    context "when the values are equal" do

      it "returns false" do
        matcher.matches?("$ne" => "first").should be_false
      end
    end

    context "when the value is an array" do

      let(:array_matcher) do
        described_class.new([ "first" ])
      end

      context "when the value is in the array" do

        it "returns false" do
          expect(array_matcher.matches?("$ne" => "first")).to be false
        end
      end

      context "when the value is not in the array" do

        it "returns true" do
          expect(array_matcher.matches?("$ne" => "second")).to be true
        end
      end
    end
  end
end
