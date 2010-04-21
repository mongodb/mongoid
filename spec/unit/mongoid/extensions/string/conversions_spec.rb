require "spec_helper"

describe Mongoid::Extensions::String::Conversions do

  describe "#set" do

    context "when the value is not nil" do

      it "returns the object to_s" do
        String.set(1).should == "1"
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        String.set(nil).should be_nil
      end
    end
  end

  describe "#get" do
    it "returns the string" do
      String.get("test").should == "test"
    end
  end

end
