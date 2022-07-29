# frozen_string_literal: true

require "spec_helper"

describe BigDecimal do

  describe ".evolve" do

    context 'when map_big_decimal_to_decimal128 is false' do
      config_override :map_big_decimal_to_decimal128, false

      context "when provided a big decimal" do

        let(:big_decimal) do
          BigDecimal("123456.789")
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
          BigDecimal("123456.789")
        end

        let(:bd_two) do
          BigDecimal("123333.789")
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

      context "when provided a numeric" do
        it "returns a string" do
          expect(described_class.evolve(1)).to eq('1')
        end
      end

      context "when provided a bogus value" do
        it "returns the value" do
          expect(described_class.evolve(:bogus)).to eq(:bogus)
        end
      end

      context "when provided a bogus string" do
        it "returns the string" do
          expect(described_class.evolve("bogus")).to eq("bogus")
        end
      end

      context "when provided a valid string" do
        it "returns the string" do
          expect(described_class.evolve("1")).to eq("1")
        end
      end
    end

    context 'when map_big_decimal_to_decimal128 is true' do
      config_override :map_big_decimal_to_decimal128, true

      context "when provided a big decimal" do

        let(:big_decimal) do
          BigDecimal("123456.789")
        end

        it "returns the decimal as a BSON::Decimal128 object" do
          expect(described_class.evolve(big_decimal)).to eq(BSON::Decimal128.new(big_decimal))
        end
      end

      context "when provided a non big decimal" do

        it "returns the object as a string" do
          expect(described_class.evolve("testing")).to eq("testing")
        end
      end

      context "when provided an array of big decimals" do

        let(:bd_one) do
          BigDecimal("123456.789")
        end

        let(:bd_two) do
          BigDecimal("123333.789")
        end

        let(:array) do
          [ bd_one, bd_two ]
        end

        let(:evolved) do
          described_class.evolve(array)
        end

        it "returns the array as BSON::Decimal128s" do
          expect(evolved).to eq([ BSON::Decimal128.new(bd_one), BSON::Decimal128.new(bd_two) ])
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

      context "when provided a numeric" do
        it "returns a string" do
          expect(described_class.evolve(1)).to eq(BSON::Decimal128.new('1'))
        end
      end

      context "when provided a bogus value" do
        it "returns the value" do
          expect(described_class.evolve(:bogus)).to eq(:bogus)
        end
      end

      context "when provided a bogus string" do
        it "returns the string" do
          expect(described_class.evolve("bogus")).to eq("bogus")
        end
      end

      context "when provided a valid string" do
        it "returns the string" do
          expect(described_class.evolve("1")).to eq("1")
        end
      end
    end
  end
end
