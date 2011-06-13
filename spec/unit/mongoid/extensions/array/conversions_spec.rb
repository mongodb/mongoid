require "spec_helper"

describe Mongoid::Extensions::Array::Conversions do

  describe "#get" do

    context "when the value is not an array" do

      it "raises an error" do
        lambda { Array.try_bson("test") }.should raise_error(Mongoid::Errors::InvalidType)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        Array.try_bson(nil).should be_nil
      end
    end

    context "when the value is an array" do

      it "returns the array" do
        Array.try_bson(["test"]).should == ["test"]
      end
    end
  end

  describe "#set" do

    context "when the value is not an array" do

      it "raises an error" do
        lambda { Array.from_bson("test") }.should raise_error(Mongoid::Errors::InvalidType)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        Array.try_bson(nil).should be_nil
      end
    end

    context "when the value is an array" do

      it "returns the array" do
        Array.from_bson(["test"]).should == ["test"]
      end
    end
  end
end
