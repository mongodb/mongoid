# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Criteria::Queryable::Extensions::Numeric::ClassMethods do

  let(:host) do
    Class.new do
      include Mongoid::Criteria::Queryable::Extensions::Numeric::ClassMethods
    end.new
  end

  describe "#__numeric__" do

    let(:actual) { host.__numeric__(str) }

    context "when the string is a whole number" do

      let(:str) { '123' }

      it "returns the value as integer" do
        expect(actual).to eq(123)
      end
    end

    context "when the string is a floating point number" do

      let(:str) { '123.45' }

      it "returns the value as a float" do
        expect(actual).to eq(123.45)
      end
    end

    context "when the string is a dot only" do

      let(:str) { '.' }

      it "returns zero" do
        expect(actual).to eq(0)
      end
    end

    context "when the string is a number with fractional part consisting of zeros" do

      let(:str) { '12.000' }

      it "returns the value as integer" do
        expect(actual).to eq(12)
      end
    end
  end
end
