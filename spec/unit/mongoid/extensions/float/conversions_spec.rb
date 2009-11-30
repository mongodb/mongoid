require "spec_helper"

describe Mongoid::Extensions::Float::Conversions do

  describe "#set" do

    it "converts the string to a float" do
      Float.set("3.45").should == 3.45
    end

  end

  describe "#get" do

    it "returns the float" do
      Float.get(3.45).should == 3.45
    end

  end

end
