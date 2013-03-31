require "spec_helper"

describe Mongoid::Matchers::Size do

  let(:matcher) do
    described_class.new(["first", "second"])
  end

  describe "#matches?" do

    context "when the attribute is the same size" do

      it "returns true" do
        expect(matcher.matches?("$size" => 2)).to be_true
      end
    end

    context "when the attribute is not the same size" do

      it "returns false" do
        expect(matcher.matches?("$size" => 5)).to be_false
      end
    end
  end
end
