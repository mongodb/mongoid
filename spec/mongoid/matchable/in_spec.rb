require "spec_helper"

describe Mongoid::Matchable::In do

  let(:matcher) do
    described_class.new("first")
  end

  describe "#matches?" do

    context "when the values include the attribute" do

      it "returns true" do
        expect(matcher.matches?("$in" => [/\Afir.*\z/, "second"])).to be_truthy
      end
    end

    context "when the values don't include the attribute" do

      it "returns false" do
        expect(matcher.matches?("$in" => ["third"])).to be_falsey
      end
    end
  end
end
