require "spec_helper"

describe Mongoid::Extensions::Integer::Conversions do

  describe "#set" do

    context "when the value is a number" do

      context "when the value is an integer" do

        it "it returns the integer" do
          Integer.from_bson(3).should == 3
        end
      end

      context "when the value is a decimal" do

        it "returns the decimal" do
          Integer.from_bson(2.5).should == 2.5
        end
      end
    end

    context "when the string is not a number" do

      context "when the string is non numerical" do

        it "returns the string" do
          Integer.from_bson("foo").should == "foo"
        end
      end

      context "when the string is numerical" do

        it "returns the integer value for the string" do
          Integer.from_bson("3").should == 3
        end
      end

      context "when the string is empty" do

        it "returns an empty string" do
          Integer.from_bson("").should be_nil
        end
      end

      context "when the string is nil" do

        it "returns nil" do
          Integer.from_bson(nil).should be_nil
        end
      end
    end
  end

  describe "#get" do

    it "returns the integer" do
      Integer.try_bson(3).should == 3
    end
  end
end
