require "spec_helper"

describe Mongoid::Extensions::Symbol do

  describe ".demongoize" do

    context "when the object is not a symbol" do

      it "returns the symbol" do
        Symbol.demongoize("test").should eq(:test)
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        Symbol.demongoize(nil).should be_nil
      end
    end
  end

  describe "#mongoid_id?" do

    context "when the string is id" do

      it "returns true" do
        :id.should be_mongoid_id
      end
    end

    context "when the string is _id" do

      it "returns true" do
        :_id.should be_mongoid_id
      end
    end

    context "when the string contains id" do

      it "returns false" do
        :identity.should_not be_mongoid_id
      end
    end

    context "when the string contains _id" do

      it "returns false" do
        :something_id.should_not be_mongoid_id
      end
    end
  end

  describe ".mongoize" do

    context "when the object is not a symbol" do

      it "returns the symbol" do
        Symbol.mongoize("test").should eq(:test)
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        Symbol.mongoize(nil).should be_nil
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      :test.mongoize.should eq(:test)
    end
  end
end
