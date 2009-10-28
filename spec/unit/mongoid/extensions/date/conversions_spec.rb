require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Date::Conversions do

  describe "#cast" do

    context "when string provided" do

      it "parses the string" do
        Date.cast("1976/11/19").should == Date.new(1976, 11, 19)
      end

    end

    context "when time provided" do

      it "parses the time" do
        Date.cast(30.seconds.ago).should == Date.today
      end

    end
  end

end
