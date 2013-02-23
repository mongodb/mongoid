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

    context "when the value is a float" do

      let(:float) do
        123456.789
      end

      it "returns a float" do
        BigDecimal.demongoize(float).should eq(float)
      end
    end

    context "when the value is an integer" do

      let(:integer) do
        123456
      end

      it "returns an integer" do
        BigDecimal.demongoize(integer).should eq(integer)
      end
    end

    context "when the value is NaN" do

      let(:nan) do
        "NaN"
      end

      let(:demongoized) do
        BigDecimal.demongoize(nan)
      end

      it "returns a big decimal" do
        demongoized.should be_a(BigDecimal)
      end

      it "is a NaN big decimal" do
        demongoized.should be_nan
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

    context "when the value is an integer" do

      it "returns a string" do
        BigDecimal.mongoize(123456).should eq("123456")
      end
    end

    context "when the value is a float" do

      it "returns a string" do
        BigDecimal.mongoize(123456.789).should eq("123456.789")
      end
    end
  end

  describe "#mongoize" do

    it "returns a string" do
      number.mongoize.should eq(number.to_s)
    end
  end
end
