require "spec_helper"

describe Mongoid::Matchers::Exists do

  describe "#matches?" do

    context "when checking for existence" do

      context "when the value exists" do

        let(:matcher) { Mongoid::Matchers::Exists.new("Test") }

        it "returns true" do
          matcher.matches?("$exists" => true).should be_true
        end

      end

      context "when the value does not exist" do

        let(:matcher) { Mongoid::Matchers::Exists.new(nil) }

        it "returns false" do
          matcher.matches?("$exists" => true).should be_false
        end

      end

    end

    context "when checking for nonexistence" do

      context "when the value exists" do

        let(:matcher) { Mongoid::Matchers::Exists.new("Test") }

        it "returns false" do
          matcher.matches?("$exists" => false).should be_false
        end

      end

      context "when the value does not exist" do

        let(:matcher) { Mongoid::Matchers::Exists.new(nil) }

        it "returns true" do
          matcher.matches?("$exists" => false).should be_true
        end

      end
    end

  end

end
