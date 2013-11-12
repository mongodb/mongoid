require "spec_helper"

describe Mongoid::Matchable::All do

  let(:matcher) do
    described_class.new(["first", "second", "third"])
  end

  describe "#matches?" do

    context "when the attribute includes all of the values" do

      it "returns true" do
        expect(matcher.matches?("$all" => ["first", /\Asec.*\z/])).to be_truthy
      end
    end

    context "when the attributes doesn't include all of the values" do

      it "returns false" do
        expect(matcher.matches?("$all" => ["second", "third", "fourth"])).to be_falsey
      end
    end

    context "when the value is empty" do
      it "returns false" do
        expect(matcher.matches?("$all" => [])).to be_falsey
      end
    end
  end
end
