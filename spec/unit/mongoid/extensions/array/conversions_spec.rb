require "spec_helper"

describe Mongoid::Extensions::Array::Conversions do

  describe "#get" do

    context "when the value is not an array" do

      it "raises an error" do
        lambda { Array.get("test") }.should raise_error(Mongoid::Errors::InvalidType)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        Array.get(nil).should be_nil
      end
    end

    context "when the value is an array" do

      it "returns the array" do
        Array.get(["test"]).should == ["test"]
      end
    end
  end

  describe "#set" do

    context "when the value is not an array" do

      it "raises an error" do
        lambda { Array.set("test") }.should raise_error(Mongoid::Errors::InvalidType)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        Array.get(nil).should be_nil
      end
    end

    context "when the value is an array" do

      it "returns the array" do
        Array.set(["test"]).should == ["test"]
      end
    end
  end
end
