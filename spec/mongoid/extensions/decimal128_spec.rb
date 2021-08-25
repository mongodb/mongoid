# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Decimal128 do

  let(:decimal128) do
    BSON::Decimal128.new("0.0005")
  end

  describe "#__evolve_decimal128__" do

    it "returns the same instance" do
      expect(decimal128.__evolve_decimal128__).to be(decimal128)
    end
  end

  describe ".evolve" do

    context "when provided a single decimal128" do

      let(:evolved) do
        BSON::Decimal128.evolve(decimal128)
      end

      it "returns the decimal128" do
        expect(evolved).to be(decimal128)
      end
    end

    context "when provided an array of decimal128s" do

      let(:other_decimal128) do
        BSON::Decimal128.new("3.14")
      end

      let(:evolved) do
        BSON::ObjectId.evolve([decimal128, other_decimal128])
      end

      it "returns the array of decimal128s" do
        expect(evolved).to eq([decimal128, other_decimal128])
      end
    end
  end
end
