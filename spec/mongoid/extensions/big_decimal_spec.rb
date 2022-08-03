# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::BigDecimal do

  let(:big_decimal) do
    BigDecimal("123456.789")
  end

  context 'when map_big_decimal_to_decimal128 is false' do
    config_override :map_big_decimal_to_decimal128, false

    describe ".demongoize" do

      let(:demongoized) do
        BigDecimal.demongoize(value)
      end

      context "when the value is an empty String" do

        let(:value) do
          ""
        end

        it "raises an error" do
          expect(demongoized).to be_nil
        end
      end

      context "when the value is a numeric String" do

        let(:value) do
          "123456.789"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to eq(BigDecimal(value))
        end
      end

      context "when the value is the numeric String zero" do

        let(:value) do
          "0.0"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to eq(BigDecimal(value))
        end
      end

      context "when the value is the numeric String negative zero" do

        let(:value) do
          "-0.0"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to eq(BigDecimal(value))
        end
      end

      context "when the value is a non-numeric String" do

        let(:value) do
          "1a2"
        end

        it "returns nil" do
          expect(demongoized).to be_nil
        end
      end

      context "when the value is nil" do

        let(:value) do
          nil
        end

        it "returns nil" do
          expect(demongoized).to be_nil
        end
      end

      context "when the value is true" do

        let(:value) do
          true
        end

        it "returns nil" do
          expect(demongoized).to be_nil
        end
      end

      context "when the value is false" do

        let(:value) do
          false
        end

        it "returns nil" do
          expect(demongoized).to be_nil
        end
      end

      context "when the value is an Integer" do

        let(:value) do
          123456
        end

        it "returns an integer" do
          expect(demongoized).to eq(value)
        end
      end

      context "when the value is a Float" do

        let(:value) do
          123456.789
        end

        it "returns a float" do
          expect(demongoized).to eq(value)
        end
      end

      context "when the value is the String 'NaN'" do

        let(:value) do
          "NaN"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to be_a(BigDecimal)
        end

        it "is a NaN BigDecimal" do
          expect(demongoized).to be_nan
        end
      end

      context "when the value is the String 'Infinity'" do

        let(:value) do
          "Infinity"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to be_a(BigDecimal)
        end

        it "is a infinity BigDecimal" do
          expect(demongoized.infinite?).to eq 1
        end
      end

      context "when the value is the String '-Infinity'" do

        let(:value) do
          "-Infinity"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to be_a(BigDecimal)
        end

        it "is a negative infinity BigDecimal" do
          expect(demongoized.infinite?).to eq -1
        end
      end

      context "when the value is a BSON::Decimal128" do

        let(:value) do
          BSON::Decimal128.new("1.2")
        end

        it "does not raise an error" do
          expect do
            demongoized
          end.to_not raise_error
        end

        it "returns a big decimal" do
          expect(demongoized).to eq(value.to_big_decimal)
        end
      end
    end

    describe ".mongoize" do

      let(:mongoized) do
        BigDecimal.mongoize(value)
      end

      context "when the value is a BigDecimal" do

        let(:value) do
          big_decimal
        end

        it "returns a string" do
          expect(mongoized).to eq(value.to_s)
        end
      end

      context "when the value is the BigDecimal zero" do

        let(:value) do
          BigDecimal("0.0")
        end

        it "returns a string" do
          expect(mongoized).to eq(value.to_s)
        end
      end

      context "when the value is the BigDecimal negative zero" do

        let(:value) do
          BigDecimal("-0.0")
        end

        it "returns a string" do
          expect(mongoized).to eq(value.to_s)
        end
      end

      context "when the value is an empty String" do

        let(:value) do
          ""
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is an integer numeric String" do

        let(:value) do
          "123456"
        end

        it "returns the String" do
          expect(mongoized).to eq(value)
        end
      end

      context "when the value is a float numeric String" do

        let(:value) do
          "123456.789"
        end

        it "returns the String" do
          expect(mongoized).to eq(value)
        end
      end

      context "when the value is a non-numeric String" do

        let(:value) do
          "1a2"
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is castable" do

        let(:value) do
          2.hours
        end

        before do
          expect(value).to be_a(ActiveSupport::Duration)
        end

        it "returns nil" do
          expect(mongoized).to eq(7200)
        end
      end

      context "when the value is nil" do

        let(:value) do
          nil
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is true" do

        let(:value) do
          true
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is false" do

        let(:value) do
          false
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is an Integer" do
        let(:value) do
          123456
        end

        it "returns a string" do
          expect(mongoized).to eq(value.to_s)
        end
      end

      context "when the value is a Float" do

        let(:value) do
          123456.789
        end

        it "returns a string" do
          expect(mongoized).to eq(value.to_s)
        end
      end

      context "when the value is String NaN" do

        let(:value) do
          "NaN"
        end

        it "returns a String" do
          expect(mongoized).to eq("NaN")
        end
      end

      context "when the value is String Infinity" do

        let(:value) do
          "Infinity"
        end

        it "returns a String" do
          expect(mongoized).to eq("Infinity")
        end
      end

      context "when the value is String negative Infinity" do

        let(:value) do
          "-Infinity"
        end

        it "returns a String" do
          expect(mongoized).to eq("-Infinity")
        end
      end

      context "when the value is BigDecimal NaN" do

        let(:value) do
          BigDecimal("NaN")
        end

        it "returns a String" do
          expect(mongoized).to eq("NaN")
        end
      end

      context "when the value is BigDecimal Infinity" do

        let(:value) do
          BigDecimal("Infinity")
        end

        it "returns a String" do
          expect(mongoized).to eq("Infinity")
        end
      end

      context "when the value is BigDecimal negative Infinity" do

        let(:value) do
          BigDecimal("-Infinity")
        end

        it "returns a String" do
          expect(mongoized).to eq("-Infinity")
        end
      end

      context "when the value is the constant Float::NAN" do

        let(:value) do
          Float::NAN
        end

        it "returns a String" do
          expect(mongoized).to eq("NaN")
        end
      end

      context "when the value is constant Float::INFINITY" do

        let(:value) do
          Float::INFINITY
        end

        it "returns a String" do
          expect(mongoized).to eq("Infinity")
        end
      end

      context "when the value is constant Float::INFINITY * -1" do

        let(:value) do
          Float::INFINITY * -1
        end

        it "returns a String" do
          expect(mongoized).to eq("-Infinity")
        end
      end

      context "when the value is a decimal128" do
        let(:value) do
          BSON::Decimal128.new("42")
        end

        it "returns a String" do
          expect(mongoized).to eq("42")
        end
      end
    end

    describe "#mongoize" do

      it "returns a string" do
        expect(big_decimal.mongoize).to eq(big_decimal.to_s)
      end
    end

    describe "#numeric?" do

      it "returns true" do
        expect(big_decimal.numeric?).to eq(true)
      end
    end
  end

  context 'when map_big_decimal_to_decimal128 is true' do
    config_override :map_big_decimal_to_decimal128, true

    describe ".demongoize" do

      let(:demongoized) do
        BigDecimal.demongoize(value)
      end

      context "when the value is an empty String" do

        let(:value) do
          ""
        end

        it "raises an error" do
          expect(demongoized).to eq(nil)
        end
      end

      context "when the value is a numeric String" do

        let(:value) do
          "123456.789"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to eq(BigDecimal(value))
        end
      end

      context "when the value is the numeric String zero" do

        let(:value) do
          "0.0"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to eq(BigDecimal(value))
        end
      end

      context "when the value is the numeric String negative zero" do

        let(:value) do
          "-0.0"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to eq(BigDecimal(value))
        end
      end

      context "when the value is a non-numeric String" do

        let(:value) do
          "1a2"
        end

        it "returns nil" do
          expect(demongoized).to be_nil
        end
      end

      context "when the value is nil" do

        let(:value) do
          nil
        end

        it "returns nil" do
          expect(demongoized).to be_nil
        end
      end

      context "when the value is an Integer" do

        let(:value) do
          123456
        end

        it "returns an integer" do
          expect(demongoized).to eq(value)
        end
      end

      context "when the value is a BSON::Decimal128 object" do

        let(:value) do
          BSON::Decimal128.new("123456")
        end

        it "returns a BigDecimal" do
          expect(demongoized).to eq(value.to_big_decimal)
        end
      end

      context "when the value is a Float" do

        let(:value) do
          123456.789
        end

        it "returns a float" do
          expect(demongoized).to eq(value)
        end
      end

      context "when the value is the String 'NaN'" do

        let(:value) do
          "NaN"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to be_a(BigDecimal)
        end

        it "is a NaN BigDecimal" do
          expect(demongoized).to be_nan
        end
      end

      context "when the value is the String 'Infinity'" do

        let(:value) do
          "Infinity"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to be_a(BigDecimal)
        end

        it "is a infinity BigDecimal" do
          expect(demongoized.infinite?).to eq 1
        end
      end

      context "when the value is the String '-Infinity'" do

        let(:value) do
          "-Infinity"
        end

        it "returns a BigDecimal" do
          expect(demongoized).to be_a(BigDecimal)
        end

        it "is a negative infinity BigDecimal" do
          expect(demongoized.infinite?).to eq -1
        end
      end

      context "when the value is true" do

        let(:value) do
          true
        end

        it "returns nil" do
          expect(demongoized).to be_nil
        end
      end

      context "when the value is false" do

        let(:value) do
          false
        end

        it "returns nil" do
          expect(demongoized).to be_nil
        end
      end
    end

    describe ".mongoize" do

      let(:mongoized) do
        BigDecimal.mongoize(value)
      end

      context "when the value is a BigDecimal" do

        let(:value) do
          big_decimal
        end

        it "returns a BSON::Decimal128" do
          expect(mongoized).to eq(BSON::Decimal128.new(value))
        end
      end

      context "when the value is the BigDecimal zero" do

        let(:value) do
          BigDecimal("0.0")
        end

        it "returns a BSON::Decimal128" do
          expect(mongoized).to eq(BSON::Decimal128.new(value))
        end
      end

      context "when the value is the BigDecimal negative zero" do

        let(:value) do
          BigDecimal("-0.0")
        end

        it "returns a BSON::Decimal128" do
          expect(mongoized).to eq(BSON::Decimal128.new(value))
        end
      end

      context "when the value is an empty String" do

        let(:value) do
          ""
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is an integer numeric String" do

        let(:value) do
          "123456"
        end

        it "returns the BSON::Decimal128" do
          expect(mongoized).to eq(BSON::Decimal128.new(value))
        end
      end

      context "when the value is a float numeric String" do

        let(:value) do
          "123456.789"
        end

        it "returns the BSON::Decimal128" do
          expect(mongoized).to eq(BSON::Decimal128.new(value))
        end
      end

      context "when the value is a non-numeric String" do

        let(:value) do
          "1a2"
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is nil" do

        let(:value) do
          nil
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is true" do

        let(:value) do
          true
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is false" do

        let(:value) do
          false
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the value is an Integer" do

        let(:value) do
          123456
        end

        it "returns a BSON::Decimal128" do
          expect(mongoized).to eq(BSON::Decimal128.new(value.to_s))
        end
      end

      context "when the value is a Float" do

        let(:value) do
          123456.789
        end

        it "returns a BSON::Decimal128" do
          expect(mongoized).to eq(BSON::Decimal128.new(value.to_s))
        end
      end

      context "when the value is String NaN" do

        let(:value) do
          "NaN"
        end

        it "returns a BSON::Decimal128 representation of NaN" do
          expect(mongoized).to eq(BSON::Decimal128.new(value))
        end
      end

      context "when the value is String Infinity" do

        let(:value) do
          "Infinity"
        end

        it "returns a BSON::Decimal128 representation of Infinity" do
          expect(mongoized).to eq(BSON::Decimal128.new(value))
        end
      end

      context "when the value is String negative Infinity" do

        let(:value) do
          "-Infinity"
        end

        it "returns a BSON::Decimal128 representation of -Infinity" do
          expect(mongoized).to eq(BSON::Decimal128.new(value))
        end
      end

      context "when the value is BigDecimal NaN" do

        let(:value) do
          BigDecimal("NaN")
        end

        it "returns a BSON::Decimal128 representation of BigDecimal NaN" do
          expect(mongoized).to eq(BSON::Decimal128.new("NaN"))
        end
      end

      context "when the value is BigDecimal Infinity" do

        let(:value) do
          BigDecimal("Infinity")
        end

        it "returns a BSON::Decimal128 representation of BigDecimal Infinity" do
          expect(mongoized).to eq(BSON::Decimal128.new("Infinity"))
        end
      end

      context "when the value is BigDecimal negative Infinity" do

        let(:value) do
          BigDecimal("-Infinity")
        end

        it "returns a BSON::Decimal128 representation of BigDecimal negative Infinity" do
          expect(mongoized).to eq(BSON::Decimal128.new("-Infinity"))
        end
      end

      context "when the value is the constant Float::NAN" do

        let(:value) do
          Float::NAN
        end

        it "returns a BSON::Decimal128 representation of NaN" do
          expect(mongoized).to eq(BSON::Decimal128.new("NaN"))
        end
      end

      context "when the value is constant Float::INFINITY" do

        let(:value) do
          Float::INFINITY
        end

        it "returns a BSON::Decimal128 representation of Infinity" do
          expect(mongoized).to eq(BSON::Decimal128.new("Infinity"))
        end
      end

      context "when the value is constant Float::INFINITY * -1" do

        let(:value) do
          Float::INFINITY * -1
        end

        it "returns a BSON::Decimal128 representation of negative Infinity" do
          expect(mongoized).to eq(BSON::Decimal128.new("-Infinity"))
        end
      end

      context "when the value is a decimal128" do
        let(:value) do
          BSON::Decimal128.new("42")
        end

        it "returns a String" do
          expect(mongoized).to eq(value)
        end
      end
    end

    describe "#mongoize" do

      it "returns a BSON::Decimal128 representation of the BigDecimal" do
        expect(big_decimal.mongoize).to eq(BSON::Decimal128.new(big_decimal))
      end
    end

    describe "#numeric?" do

      it "returns true" do
        expect(big_decimal.numeric?).to eq(true)
      end
    end
  end
end
