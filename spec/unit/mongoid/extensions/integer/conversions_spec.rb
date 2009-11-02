require File.expand_path(File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb"))

describe Mongoid::Extensions::Integer::Conversions do

  describe "#set" do

    context "when string is a number" do

      it "converts the string to an Integer" do
        Integer.set("32").should == 32
      end

    end

    context "when string is not a number" do

      it "returns the string" do
        Integer.set("foo").should == "foo"
      end

    end

  end

  describe "#get" do

    it "returns the integer" do
      Integer.get(44).should == 44
    end

  end

end
