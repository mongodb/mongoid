require "spec_helper"

describe Mongoid::Extensions::Boolean::Conversions do

  describe ".mongoize" do

    context "when 'true'" do

      it "returns true" do
        Boolean.mongoize("true").should be_true
      end
    end

    context "when 'false'" do

      it "returns false" do
        Boolean.mongoize("false").should be_false
      end
    end

    context "when 0" do

      it "returns false" do
        Boolean.mongoize("0").should be_false
      end
    end

    context "when 1" do

      it "returns true" do
        Boolean.mongoize("1").should be_true
      end
    end

    context "when nil" do

      it "returns nil" do
        Boolean.mongoize(nil).should be_nil
      end
    end
  end
end
