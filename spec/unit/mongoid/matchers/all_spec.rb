require "spec_helper"

describe Mongoid::Matchers::All do

  let(:matcher) do
    described_class.new(["first", "second"])
  end

  describe "#matches?" do

    context "when the values are equal" do

      it "returns true" do
        matcher.matches?("$all" => ["first", "second"]).should be_true
      end
    end

    context "when the values are not equal" do

      it "returns false" do
        matcher.matches?("$all" => ["first"]).should be_false
      end
    end
  end
end
