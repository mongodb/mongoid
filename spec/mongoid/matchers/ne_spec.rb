require "spec_helper"

describe Mongoid::Matchers::Ne do

  let(:matcher) do
    described_class.new("first")
  end

  describe "#matches?" do

    context "when the values are not equal" do

      it "returns true" do
        expect(matcher.matches?("$ne" => "second")).to be_true
      end
    end

    context "when the values are equal" do

      it "returns false" do
        expect(matcher.matches?("$ne" => "first")).to be_false
      end
    end
  end
end
