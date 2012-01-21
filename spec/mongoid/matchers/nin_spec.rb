require "spec_helper"

describe Mongoid::Matchers::Nin do

  let(:matcher) do
    described_class.new("first")
  end

  describe "#matches?" do

    context "when the values do not contain the attribute" do

      it "returns true" do
        matcher.matches?("$nin" => ["second", "third"]).should be_true
      end
    end

    context "when the values contain the attribute" do

      it "returns false" do
        matcher.matches?("$nin" => ["first"]).should be_false
      end
    end
  end
end
