require "spec_helper"

describe Mongoid::Extensions::BigDecimal::Conversions do

  let(:number) do
    BigDecimal.new("123456.789")
  end

  describe "#get" do

    it "converts the string to a big decimal" do
      BigDecimal.get("123456.789").should == number
    end

    context "when nil" do

      it "returns nil" do
        BigDecimal.get(nil).should be_nil
      end
    end
  end

  describe "#set" do

    it "converts the big decimal to a string" do
      BigDecimal.set(number).should == "123456.789"
    end

    context "when nil" do

      it "returns nil" do
        BigDecimal.set(nil).should be_nil
      end
    end
  end
end
