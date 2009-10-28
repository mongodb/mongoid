require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::String::Conversions do

  describe "#cast" do
    it "returns the object to_s" do
      String.cast(1).should == "1"
    end
  end
end
