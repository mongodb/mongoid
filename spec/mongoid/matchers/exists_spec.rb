require "spec_helper"

describe Mongoid::Matchers::Exists do

  describe "#matches?" do

    context "when checking for existence" do

      context "when the value exists" do

        let(:matcher) do
          described_class.new("Test")
        end

        it "returns true" do
          expect(matcher.matches?("$exists" => true)).to be_true
        end
      end

      context "when the value does not exist" do

        let(:matcher) do
          described_class.new(nil)
        end

        it "returns false" do
          expect(matcher.matches?("$exists" => true)).to be_false
        end
      end
    end

    context "when checking for nonexistence" do

      context "when the value exists" do

        let(:matcher) do
          described_class.new("Test")
        end

        it "returns false" do
          expect(matcher.matches?("$exists" => false)).to be_false
        end
      end

      context "when the value does not exist" do

        let(:matcher) do
          described_class.new(nil)
        end

        it "returns true" do
          expect(matcher.matches?("$exists" => false)).to be_true
        end
      end
    end
  end
end
