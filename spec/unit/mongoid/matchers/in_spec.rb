require "spec_helper"

describe Mongoid::Matchers::In do

  let(:matcher) { Mongoid::Matchers::In.new("first") }

  describe "#matches?" do

    context "when the values includes the attribute" do

      it "returns true" do
        matcher.matches?("$in" => ["first", "second"]).should be_true
      end

    end

    context "when the values dont include the atribute" do

      it "returns false" do
        matcher.matches?("$in" => ["third"]).should be_false
      end

    end

  end

end
