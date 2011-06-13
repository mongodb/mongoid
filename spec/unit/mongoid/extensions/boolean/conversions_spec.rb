require "spec_helper"

describe Mongoid::Extensions::Boolean::Conversions do

  describe ".from_bson" do

    context "when 'true'" do

      it "returns true" do
        Boolean.from_bson("true").should be_true
      end
    end

    context "when 'false'" do

      it "returns false" do
        Boolean.from_bson("false").should be_false
      end
    end

    context "when 0" do

      it "returns false" do
        Boolean.from_bson("0").should be_false
      end
    end

    context "when 1" do

      it "returns true" do
        Boolean.from_bson("1").should be_true
      end
    end

    context "when nil" do

      it "returns nil" do
        Boolean.from_bson(nil).should be_nil
      end
    end
  end

  describe ".try_bson" do

    it "returns the boolean" do
      Boolean.try_bson(false).should be_false
    end
  end
end
