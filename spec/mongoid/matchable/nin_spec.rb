require "spec_helper"

describe Mongoid::Matchable::Nin do

  let(:matcher) do
    described_class.new("first")
  end

  describe "#matches?" do

    context "when the values do not contain the attribute" do

      it "returns true" do
        expect(matcher.matches?("$nin" => ["second", "third"])).to be_truthy
      end
    end

    context "when the values contain the attribute" do

      it "returns false" do
        expect(matcher.matches?("$nin" => ["first"])).to be_falsey
      end
    end
  end
end
