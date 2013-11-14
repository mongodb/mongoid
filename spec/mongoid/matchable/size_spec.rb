require "spec_helper"

describe Mongoid::Matchable::Size do

  let(:matcher) do
    described_class.new(["first", "second"])
  end

  describe "#matches?" do

    context "when the attribute is the same size" do

      it "returns true" do
        expect(matcher.matches?("$size" => 2)).to be true
      end
    end

    context "when the attribute is not the same size" do

      it "returns false" do
        expect(matcher.matches?("$size" => 5)).to be false
      end
    end
  end
end
