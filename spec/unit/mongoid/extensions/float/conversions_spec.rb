require "spec_helper"

describe Mongoid::Extensions::Float::Conversions do

  describe "#set" do

    context "when the value is a number" do

      it "converts the number to a float" do
        Float.set(3.45).should == 3.45
      end

    end

    context "when the string is not a number" do

      context "when the string is non numerical" do

        it "returns the string" do
          Float.set("foo").should == "foo"
        end

      end

      context "when the string is numerical" do

        it "returns the float value for the string" do
          Float.set("3.45").should == 3.45
        end

      end

      context "when the string is empty" do

        it "returns 0.0" do
          Float.set("").should == 0.0
        end

      end

      context "when the string is nil" do

        it "returns 0.0" do
          Float.set(nil).should == 0.0
        end

      end

    end

  end

  describe "#get" do

    it "returns the float" do
      Float.get(3.45).should == 3.45
    end

  end

end
