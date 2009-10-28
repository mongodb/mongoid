require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Float::Conversions do

  describe "#cast" do

    it "converts the string to a float" do
      Float.cast("3.45").should == 3.45
    end

  end

end
