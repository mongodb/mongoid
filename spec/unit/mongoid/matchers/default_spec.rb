require "spec_helper"

describe Mongoid::Matchers::Default do

  let(:matcher) { Mongoid::Matchers::Default.new("Testing") }

  describe "#matches?" do

    context "when the values are equal" do

      it "returns true" do
        matcher.matches?("Testing").should be_true
      end

    end

    context "when the values are not equal" do

      it "returns false" do
        matcher.matches?("Other").should be_false
      end

    end

  end

end
