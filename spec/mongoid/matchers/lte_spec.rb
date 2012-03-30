require "spec_helper"

describe Mongoid::Matchers::Lte do

  describe "#matches?" do

    context "when the value is larger" do

      let(:matcher) do
        described_class.new(5)
      end

      it "returns false" do
        matcher.matches?("$lte" => 3).should be_false
      end
    end

    context "when the value is smaller" do

      let(:matcher) do
        described_class.new(5)
      end

      it "returns true" do
        matcher.matches?("$lte" => 10).should be_true
      end
    end

    context "when the value is equal" do

      let(:matcher) do
        described_class.new(5)
      end

      it "returns true" do
        matcher.matches?("$lte" => 5).should be_true
      end
    end

    context "when the value is nil" do

      let(:matcher) do
        described_class.new(nil)
      end

      it "returns false" do
        matcher.matches?("$lte" => 5).should be_false
      end
    end

    context "when the value is an array" do
      context "there are value valid" do
        let(:matcher) do
          described_class.new([3, 4])
        end

        it "returns true" do
          matcher.matches?("$lte" => 5).should be_true
        end
      end

      context "there are not value valid" do
        let(:matcher) do
          described_class.new([7,6])
        end

        it "returns false" do
          matcher.matches?("$lte" => 5).should be_false
        end

      end
    end
  end
end
