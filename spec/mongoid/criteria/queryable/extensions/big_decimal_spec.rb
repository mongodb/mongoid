require "spec_helper"

describe BigDecimal do

  describe ".evolve" do

    context "when provided a big decimal" do

      let(:big_decimal) do
        BigDecimal.new("123456.789")
      end

      it "returns the decimal as a string" do
        expect(described_class.evolve(big_decimal)).to eq(big_decimal.to_s)
      end
    end

    context "when provided a non big decimal" do

      it "returns the object as a string" do
        expect(described_class.evolve("testing")).to eq("testing")
      end
    end

    context "when provided an array of big decimals" do

      let(:bd_one) do
        BigDecimal.new("123456.789")
      end

      let(:bd_two) do
        BigDecimal.new("123333.789")
      end

      let(:array) do
        [ bd_one, bd_two ]
      end

      let(:evolved) do
        described_class.evolve(array)
      end

      it "returns the array as strings" do
        expect(evolved).to eq([ bd_one.to_s, bd_two.to_s ])
      end

      it "does not evolve in place" do
        expect(evolved).to_not equal(array)
      end
    end

    context "when provided nil" do

      it "returns nil" do
        expect(described_class.evolve(nil)).to be_nil
      end
    end
  end
end
