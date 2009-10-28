require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::Boolean::Conversions do

  describe "#cast" do

    context "when 'true'" do

      it "returns true" do
        Boolean.cast("true").should be_true
      end

    end

    context "when 'false'" do

      it "returns false" do
        Boolean.cast("false").should be_false
      end

    end

  end

end
