require "spec_helper"

describe Mongoid::Matchers::Default do

  describe "#matches?" do

    context "when comparing strings" do

      let(:matcher) do
        Mongoid::Matchers::Default.new("Testing")
      end

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

    context "when comparing object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:matcher) do
        Mongoid::Matchers::Default.new(object_id)
      end

      context "when the values are equal" do

        it "returns true" do
          matcher.matches?(object_id).should be_true
        end
      end

      context "when the values are not equal" do

        it "returns false" do
          matcher.matches?(BSON::ObjectId.new).should be_false
        end
      end
    end

    context "when comparing a string to an array" do

      let(:matcher) do
        Mongoid::Matchers::Default.new(["Test1", "Test2", "Test3"])
      end

      context "when the attribute contains the value" do

        it "returns true" do
          matcher.matches?("Test1").should be_true
        end
      end

      context "when the attribute does not contain the value" do

        it "returns false" do
          matcher.matches?("Test4").should be_false
        end
      end
    end

    context "when comparing an object id to an array" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:matcher) do
        Mongoid::Matchers::Default.new([ object_id, BSON::ObjectId.new ])
      end

      context "when the attribute contains the value" do

        it "returns true" do
          matcher.matches?(object_id).should be_true
        end
      end

      context "when the attribute does not contain the value" do

        it "returns false" do
          matcher.matches?(BSON::ObjectId.new).should be_false
        end
      end
    end
    
    context "when comparing an array to an array" do

      let(:matcher) do
        Mongoid::Matchers::Default.new(["Test1", "Test2", "Test3"])
      end

      context "when the attribute contains the value" do

        it "returns true" do
          matcher.matches?(["Test1", "Test2", "Test3"]).should be_true
        end
      end

      context "when the attribute does not contain the value" do

        it "returns false" do
          matcher.matches?(["Test1", "Test2"]).should be_false
        end
      end
    end
  end
end
