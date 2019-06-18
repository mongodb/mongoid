# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Extensions::BigDecimal do

  let(:big_decimal) do
    BigDecimal("123456.789")
  end

  describe ".demongoize" do

    context "when the value is an empty String" do

      let(:string) do
        ""
      end

      it "returns nil" do
        expect(BigDecimal.demongoize(string)).to be_nil
      end
    end

    context "when the value is a numeric String" do

      let(:string) do
        "123456.789"
      end

      it "returns a BigDecimal" do
        expect(BigDecimal.demongoize(string)).to eq(BigDecimal(string))
      end
    end

    context "when the value is the numeric String zero" do

      let(:string) do
        "0.0"
      end

      it "returns a BigDecimal" do
        expect(BigDecimal.demongoize(string)).to eq(BigDecimal(string))
      end
    end

    context "when the value is the numeric String negative zero" do

      let(:string) do
        "-0.0"
      end

      it "returns a BigDecimal" do
        expect(BigDecimal.demongoize(string)).to eq(BigDecimal(string))
      end
    end

    context "when the value is a non-numeric String" do

      let(:string) do
        "1a2"
      end

      it "returns nil" do
        expect(BigDecimal.demongoize(string)).to be_nil
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        expect(BigDecimal.demongoize(nil)).to be_nil
      end
    end

    context "when the value is true" do

      let(:value) do
        true
      end

      it "returns nil" do
        expect(BigDecimal.demongoize(value)).to be_nil
      end
    end

    context "when the value is false" do

      let(:value) do
        false
      end

      it "returns nil" do
        expect(BigDecimal.demongoize(value)).to be_nil
      end
    end

    context "when the value is an Integer" do

      let(:integer) do
        123456
      end

      it "returns an integer" do
        expect(BigDecimal.demongoize(integer)).to eq(integer)
      end
    end

    context "when the value is a Float" do

      let(:float) do
        123456.789
      end

      it "returns a float" do
        expect(BigDecimal.demongoize(float)).to eq(float)
      end
    end

    context "when the value is the String 'NaN'" do

      let(:nan) do
        "NaN"
      end

      let(:demongoized) do
        BigDecimal.demongoize(nan)
      end

      it "returns a BigDecimal" do
        expect(demongoized).to be_a(BigDecimal)
      end

      it "is a NaN BigDecimal" do
        expect(demongoized).to be_nan
      end
    end

    context "when the value is the String 'Infinity'" do

      let(:infinity) do
        "Infinity"
      end

      let(:demongoized) do
        BigDecimal.demongoize(infinity)
      end

      it "returns a BigDecimal" do
        expect(demongoized).to be_a(BigDecimal)
      end

      it "is a infinity BigDecimal" do
        expect(demongoized.infinite?).to eq 1
      end
    end

    context "when the value is the String '-Infinity'" do

      let(:neg_infinity) do
        "-Infinity"
      end

      let(:demongoized) do
        BigDecimal.demongoize(neg_infinity)
      end

      it "returns a BigDecimal" do
        expect(demongoized).to be_a(BigDecimal)
      end

      it "is a negative infinity BigDecimal" do
        expect(demongoized.infinite?).to eq -1
      end
    end
  end

  describe ".mongoize" do

    context "when the value is a BigDecimal" do

      it "returns a string" do
        expect(BigDecimal.mongoize(big_decimal)).to eq(big_decimal.to_s)
      end
    end

    context "when the value is the BigDecimal zero" do

      let(:big_decimal) do
        BigDecimal("0.0")
      end

      it "returns a BigDecimal" do
        expect(BigDecimal.mongoize(big_decimal)).to eq(big_decimal.to_s)
      end
    end

    context "when the value is the BigDecimal negative zero" do

      let(:big_decimal) do
        BigDecimal("-0.0")
      end

      it "returns a BigDecimal" do
        expect(BigDecimal.mongoize(big_decimal)).to eq(big_decimal.to_s)
      end
    end

    context "when the value is an empty String" do

      let(:string) do
        ""
      end

      it "returns nil" do
        expect(BigDecimal.mongoize(string)).to be_nil
      end
    end

    context "when the value is an integer numeric String" do

      let(:string) do
        "123456"
      end

      it "returns the String" do
        expect(BigDecimal.mongoize(string)).to eq string
      end
    end

    context "when the value is a float numeric String" do

      let(:string) do
        "123456.789"
      end

      it "returns the String" do
        expect(BigDecimal.mongoize(string)).to eq string
      end
    end

    context "when the value is a non-numeric String" do

      let(:string) do
        "1a2"
      end

      it "returns nil" do
        expect(BigDecimal.mongoize(string)).to be_nil
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        expect(BigDecimal.mongoize(nil)).to be_nil
      end
    end

    context "when the value is true" do

      let(:value) do
        true
      end

      it "returns nil" do
        expect(BigDecimal.mongoize(value)).to be_nil
      end
    end

    context "when the value is false" do

      let(:value) do
        false
      end

      it "returns nil" do
        expect(BigDecimal.mongoize(value)).to be_nil
      end
    end

    context "when the value is an Integer" do

      it "returns a string" do
        expect(BigDecimal.mongoize(123456)).to eq("123456")
      end
    end

    context "when the value is a Float" do

      it "returns a string" do
        expect(BigDecimal.mongoize(123456.789)).to eq("123456.789")
      end
    end

    context "when the value is String NaN" do

      let(:nan) do
        "NaN"
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(nan)).to eq("NaN")
      end
    end

    context "when the value is String Infinity" do

      let(:infinity) do
        "Infinity"
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(infinity)).to eq("Infinity")
      end
    end

    context "when the value is String negative Infinity" do

      let(:neg_infinity) do
        "-Infinity"
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(neg_infinity)).to eq("-Infinity")
      end
    end

    context "when the value is BigDecimal NaN" do

      let(:nan) do
        BigDecimal("NaN")
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(nan)).to eq("NaN")
      end
    end

    context "when the value is BigDecimal Infinity" do

      let(:infinity) do
        BigDecimal("Infinity")
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(infinity)).to eq("Infinity")
      end
    end

    context "when the value is BigDecimal negative Infinity" do

      let(:neg_infinity) do
        BigDecimal("-Infinity")
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(neg_infinity)).to eq("-Infinity")
      end
    end

    context "when the value is the constant Float::NAN" do

      let(:nan) do
        Float::NAN
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(nan)).to eq("NaN")
      end
    end

    context "when the value is constant Float::INFINITY" do

      let(:infinity) do
        Float::INFINITY
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(infinity)).to eq("Infinity")
      end
    end

    context "when the value is constant Float::INFINITY * -1" do

      let(:neg_infinity) do
        Float::INFINITY * -1
      end

      it "returns a String" do
        expect(BigDecimal.mongoize(neg_infinity)).to eq("-Infinity")
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
