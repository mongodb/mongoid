require "spec_helper"

describe Mongoid::Matchers::Lte do

  describe "#matches?" do

    context "when the value is larger" do

      let(:matcher) { Mongoid::Matchers::Lte.new(5) }

      it "returns false" do
        matcher.matches?("$lte" => 3).should be_false
      end

    end

    context "when the value is smaller" do

      let(:matcher) { Mongoid::Matchers::Lte.new(5) }

      it "returns true" do
        matcher.matches?("$lte" => 10).should be_true
      end

    end

    context "when the value is equal" do

      let(:matcher) { Mongoid::Matchers::Lte.new(5) }

      it "returns true" do
        matcher.matches?("$lte" => 5).should be_true
      end

    end

    context "when the value is nil" do

      let(:matcher) { Mongoid::Matchers::Lte.new(nil) }

      it "returns false" do
        matcher.matches?("$lte" => 5).should be_false
      end

    end

  end

end
