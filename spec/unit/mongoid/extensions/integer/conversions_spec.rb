require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Integer::Conversions do

  describe "#cast" do

    context "when string is a number" do

      it "converts the string to an Integer" do
        Integer.cast("32").should == 32
      end

    end

    context "when string is not a number" do

      it "returns the string" do
        Integer.cast("foo").should == "foo"
      end

    end
  end

end
