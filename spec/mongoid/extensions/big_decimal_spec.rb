require "spec_helper"

describe Mongoid::Extensions::BigDecimal do

  let(:number) do
    BigDecimal.new("123456.789")
  end

  describe ".demongoize" do

    context "when the the value is a string" do

      it "returns a big decimal" do
        BigDecimal.demongoize(number.to_s).should eq(number)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        BigDecimal.demongoize(nil).should be_nil
      end
    end
  end

  describe ".mongoize" do

    context "when the value is a big decimal" do

      it "returns a string" do
        BigDecimal.mongoize(number).should eq(number.to_s)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        BigDecimal.mongoize(nil).should be_nil
      end
    end
  end

  describe "#mongoize" do

    it "returns a string" do
      number.mongoize.should eq(number.to_s)
    end
  end
end
