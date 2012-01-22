require "spec_helper"

describe Mongoid::Matchers::In do

  let(:matcher) do
    described_class.new("first")
  end

  describe "#matches?" do

    context "when the values include the attribute" do

      it "returns true" do
        matcher.matches?("$in" => [/\Afir.*\z/, "second"]).should be_true
      end
    end

    context "when the values don't include the attribute" do

      it "returns false" do
        matcher.matches?("$in" => ["third"]).should be_false
      end
    end
  end
end
