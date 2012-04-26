require "spec_helper"

describe Mongoid::Matchers::All do

  let(:matcher) do
    described_class.new(["first", "second", "third"])
  end

  describe "#matches?" do

    context "when the attribute includes all of the values" do

      it "returns true" do
        matcher.matches?("$all" => ["first", /\Asec.*\z/]).should be_true
      end
    end

    context "when the attributes doesn't include all of the values" do

      it "returns false" do
        matcher.matches?("$all" => ["second", "third", "fourth"]).should be_false
      end
    end

    context "when the value is empty" do
      it "returns false" do
        matcher.matches?("$all" => []).should be_false
      end
    end
  end
end
