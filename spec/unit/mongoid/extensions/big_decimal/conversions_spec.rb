require "spec_helper"

describe Mongoid::Extensions::BigDecimal::Conversions do

  let(:number) do
    BigDecimal.new("123456.789")
  end

  describe "#get" do

    it "converts the string to a big decimal" do
      BigDecimal.try_bson("123456.789").should == number
    end

    context "when nil" do

      it "returns nil" do
        BigDecimal.try_bson(nil).should be_nil
      end
    end
  end

  describe "#set" do

    it "converts the big decimal to a string" do
      BigDecimal.from_bson(number).should == "123456.789"
    end

    context "when nil" do

      it "returns nil" do
        BigDecimal.from_bson(nil).should be_nil
      end
    end
  end
end
