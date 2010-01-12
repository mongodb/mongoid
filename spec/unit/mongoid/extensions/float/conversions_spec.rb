require "spec_helper"

describe Mongoid::Extensions::Float::Conversions do

  describe "#set" do

    context "when the string is a number" do

      it "converts the string to a float" do
        Float.set("3.45").should == 3.45
      end

    end

    context "when the string is not a number" do

      it "returns the string" do
        Float.set("foo").should == "foo"
      end

    end

  end

  describe "#get" do

    it "returns the float" do
      Float.get(3.45).should == 3.45
    end

  end

end
