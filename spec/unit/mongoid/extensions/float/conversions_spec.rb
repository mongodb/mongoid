require "spec_helper"

describe Mongoid::Extensions::Float::Conversions do

  describe "#set" do

    context "when the value is a number" do

      it "converts the number to a float" do
        Float.from_bson(3.45).should == 3.45
      end

    end

    context "when the value is not a number" do

      context "when the value is non numerical" do

        it "returns the string" do
          Float.from_bson("foo").should == "foo"
        end

      end

      context "when the string is numerical" do

        it "returns the float value for the string" do
          Float.from_bson("3.45").should == 3.45
        end

      end

      context "when the string is empty" do

        it "returns 0.0" do
          Float.from_bson("").should be_nil
        end

      end

      context "when the string is nil" do

        it "returns 0.0" do
          Float.from_bson(nil).should be_nil
        end

      end

    end

  end

  describe "#get" do

    it "returns the float" do
      Float.try_bson(3.45).should == 3.45
    end

  end

end
