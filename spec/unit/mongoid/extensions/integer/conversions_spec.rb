require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Integer::Conversions do

  describe "#cast" do
    it "converts the string to an Integer" do
      Integer.cast("32").should == 32
    end
  end

end
