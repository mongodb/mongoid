require "spec_helper"

describe Mongoid::Matchers::Lt do

  describe "#matches?" do

    context "when the value is larger" do

      let(:matcher) { Mongoid::Matchers::Lt.new(5) }

      it "returns false" do
        matcher.matches?("$lt" => 3).should be_false
      end

    end

    context "when the value is smaller" do

      let(:matcher) { Mongoid::Matchers::Lt.new(5) }

      it "returns true" do
        matcher.matches?("$lt" => 10).should be_true
      end

    end

    context "when the value is nil" do

      let(:matcher) { Mongoid::Matchers::Lt.new(nil) }

      it "returns false" do
        matcher.matches?("$lt" => 5).should be_false
      end

    end

  end

end
