require "spec_helper"

describe Mongoid::Extensions::String::Conversions do

  describe ".try_bson" do

    it "returns the string" do
      String.try_bson("test").should == "test"
    end
  end

  describe ".from_bson" do

    context "when the value is not nil" do

      it "returns the object to_s" do
        String.from_bson(1).should == "1"
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        String.from_bson(nil).should be_nil
      end
    end
  end

  describe "#to_a" do

    let(:value) do
      "Disintegration is the best album ever!"
    end

    it "returns an array with the string in it" do
      value.to_a.should == [ value ]
    end
  end
end
