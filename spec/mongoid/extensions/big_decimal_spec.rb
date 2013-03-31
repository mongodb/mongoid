require "spec_helper"

describe Mongoid::Extensions::BigDecimal do

  let(:number) do
    BigDecimal.new("123456.789")
  end

  describe ".demongoize" do

    context "when the the value is a string" do

      it "returns a big decimal" do
        expect(BigDecimal.demongoize(number.to_s)).to eq(number)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        expect(BigDecimal.demongoize(nil)).to be_nil
      end
    end

    context "when the value is a float" do

      let(:float) do
        123456.789
      end

      it "returns a float" do
        expect(BigDecimal.demongoize(float)).to eq(float)
      end
    end

    context "when the value is an integer" do

      let(:integer) do
        123456
      end

      it "returns an integer" do
        expect(BigDecimal.demongoize(integer)).to eq(integer)
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
        expect(demongoized).to be_a(BigDecimal)
      end

      it "is a NaN big decimal" do
        expect(demongoized).to be_nan
      end
    end
  end

  describe ".mongoize" do

    context "when the value is a big decimal" do

      it "returns a string" do
        expect(BigDecimal.mongoize(number)).to eq(number.to_s)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        expect(BigDecimal.mongoize(nil)).to be_nil
      end
    end

    context "when the value is an integer" do

      it "returns a string" do
        expect(BigDecimal.mongoize(123456)).to eq("123456")
      end
    end

    context "when the value is a float" do

      it "returns a string" do
        expect(BigDecimal.mongoize(123456.789)).to eq("123456.789")
      end
    end
  end

  describe "#mongoize" do

    it "returns a string" do
      expect(number.mongoize).to eq(number.to_s)
    end
  end
end
