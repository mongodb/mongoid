require "spec_helper"

describe Mongoid::Matchable::In do

  describe "#matches?" do

    context 'when the attribute is not nil' do

      let(:matcher) do
        described_class.new("first")
      end

      context "when the values include the attribute" do

        it "returns true" do
          expect(matcher.matches?("$in" => [/\Afir.*\z/, "second"])).to be true
        end
      end

      context "when the values don't include the attribute" do

        it "returns false" do
          expect(matcher.matches?("$in" => ["third"])).to be false
        end
      end
    end

    context 'when the attribute is nil' do

      let(:matcher) do
        described_class.new(nil)
      end

      context "when the values include the attribute" do

        it "returns true" do
          expect(matcher.matches?("$in" => [/\Afir.*\z/, nil])).to be true
        end
      end

      context "when the values don't include the attribute" do

        it "returns false" do
          expect(matcher.matches?("$in" => ["third"])).to be false
        end
      end
    end
  end
end
