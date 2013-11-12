require "spec_helper"

describe Mongoid::Matchable::Ne do

  let(:matcher) do
    described_class.new("first")
  end

  describe "#matches?" do

    context "when the values are not equal" do

      it "returns true" do
        expect(matcher.matches?("$ne" => "second")).to be_truthy
      end
    end

    context "when the values are equal" do

      it "returns false" do
        expect(matcher.matches?("$ne" => "first")).to be_falsey
      end
    end
  end
end
