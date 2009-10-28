require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Time::Conversions do

  describe "#cast" do
    context "when value is a string" do
      it "converts to a time" do
        time = Time.local(1976, 11, 19).utc
        Time.cast(time.to_s).should == time
      end
    end
  end

end
