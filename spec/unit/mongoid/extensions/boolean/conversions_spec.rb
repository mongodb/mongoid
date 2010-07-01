require "spec_helper"

describe Mongoid::Extensions::Boolean::Conversions do

  describe ".set" do

    context "when 'true'" do

      it "returns true" do
        Boolean.set("true").should be_true
      end
    end

    context "when 'false'" do

      it "returns false" do
        Boolean.set("false").should be_false
      end
    end

    context "when 0" do

      it "returns false" do
        Boolean.set("0").should be_false
      end
    end

    context "when 1" do

      it "returns true" do
        Boolean.set("1").should be_true
      end
    end

    context "when nil" do

      it "returns nil" do
        Boolean.set(nil).should be_nil
      end
    end
  end

  describe ".get" do

    it "returns the boolean" do
      Boolean.get(false).should be_false
    end
  end
end
