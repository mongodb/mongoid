# frozen_string_literal: true

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

      it "returns the value as an integer" do
        expect(actual).to eq(123)
        expect(actual).to be_a Integer
      end
    end

    context "when the string is a floating point number" do
      let(:str) { '123.45' }

      it "returns the value as a float" do
        expect(actual).to eq(123.45)
        expect(actual).to be_a Float
      end
    end

    context "when the string is a floating point number with a leading dot" do
      let(:str) { '.45' }

      it "returns the value as a float" do
        expect(actual).to eq(0.45)
        expect(actual).to be_a Float
      end
    end

    context "when the string is a dot only" do
      let(:str) { '.' }

      it "returns zero" do
        expect(actual).to eq(0)
        expect(actual).to be_a Integer
      end
    end

    context "when the string is a number with a trailing dot" do
      let(:str) { '123.' }

      it "returns zero" do
        expect(actual).to eq(123)
        expect(actual).to be_a Integer
      end
    end

    context "when the string is a number with fractional part consisting of zeros" do
      let(:str) { '12.000' }

      it "returns the value as an integer" do
        expect(actual).to eq(12)
        expect(actual).to be_a Integer
      end
    end

    context "when the string is a number with leading dot then zeros" do
      let(:str) { '.000' }

      it "returns the value as an integer" do
        expect(actual).to eq(0)
        expect(actual).to be_a Integer
      end
    end

    context "when the string is non-numeric" do
      let(:str) { 'foo' }

      it "raises ArgumentError" do
        expect { actual }.to raise_error(ArgumentError)
      end
    end

    context "when the string is non-numeric with leading dot" do
      let(:str) { '.foo' }

      it "raises ArgumentError" do
        expect { actual }.to raise_error(ArgumentError)
      end
    end

    context "when the string is non-numeric with trailing dot" do
      let(:str) { 'foo.' }

      it "raises ArgumentError" do
        expect { actual }.to raise_error(ArgumentError)
      end
    end

    context "when the string is non-numeric with trailing dot and zeroes" do
      let(:str) { 'foo.000' }

      it "raises ArgumentError" do
        expect { actual }.to raise_error(ArgumentError)
      end
    end

    context "when the string is empty" do
      let(:str) { '' }

      it "raises ArgumentError" do
        expect { actual }.to raise_error(ArgumentError)
      end
    end
  end
end
