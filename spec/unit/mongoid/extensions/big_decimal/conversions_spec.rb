require "spec_helper"

describe Mongoid::Extensions::BigDecimal::Conversions do

  let(:number) do
    BigDecimal.new("123456.789")
  end

  describe "#get" do

    it "converts the string to a big decimal" do
      BigDecimal.get("123456.789").should == number
    end
  end

  describe "#set" do

    it "converts the big decimal to a string" do
      BigDecimal.set(number).should == "123456.789"
    end
  end
end
