require "spec_helper"

describe Mongoid::Extensions::Integer::Conversions do

  describe "#set" do

    context "when the value is a number" do

      it "converts the number to an integer" do
        Integer.set(3).should == 3
      end

    end

    context "when the string is not a number" do

      context "when the string is non numerical" do

        it "returns the string" do
          Integer.set("foo").should == "foo"
        end

      end

      context "when the string is numerical" do

        it "returns the integer value for the string" do
          Integer.set("3").should == 3
        end

      end

      context "when the string is empty" do

        it "returns an empty string" do
          Integer.set("").should be_blank
        end

      end

      context "when the string is nil" do

        it "returns nil" do
          Integer.set(nil).should be_nil
        end

      end

    end

  end

  describe "#get" do

    it "returns the integer" do
      Integer.get(3).should == 3
    end

  end

end
