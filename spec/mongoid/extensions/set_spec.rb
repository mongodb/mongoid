# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Set do

  describe "#demongoize" do

    it "returns the set if Array" do
      expect(Set.demongoize([ "test" ])).to eq(Set.new([ "test" ]))
    end
  end

  describe ".mongoize" do

    it "returns an array" do
      expect(Set.mongoize([ "test" ])).to eq([ "test" ])
    end

    it "returns an array even if the value is a set" do
      expect(Set.mongoize(Set.new([ "test" ]))).to eq([ "test" ])
    end
  end

  describe ".demongoize" do

    context "when passing an array" do

      it "returns a set" do
        expect(Set.demongoize([ "test" ])).to eq([ "test" ].to_set)
      end
    end

    context "when passing a set" do

      it "returns a set " do
        expect(Set.demongoize(Set.new([ "test" ]))).to eq([ "test" ].to_set)
      end
    end

    context "when passing nil" do

      it "returns nil" do
        expect(Set.demongoize(nil)).to be_nil
      end
    end

    context "when passing an uncastable value" do

      it "returns nil" do
        expect(Set.demongoize("bogus")).to be_nil
      end
    end
  end

  describe "#mongoize" do

    let(:set) do
      Set.new([ "test" ])
    end

    it "returns an array" do
      expect(set.mongoize).to eq([ "test" ])
    end

    context "when there are mongoizable values in the container" do
      let(:date) do
        Date.new(2012, 1, 1)
      end

      let(:mongoized) do
        Set.mongoize(input)
      end

      context "when the input is an array" do

        let(:input) do
          [ date ]
        end

        it "mongoizes to a set" do
          expect(mongoized).to be_a(Array)
        end

        it "mongoizes each element in the array" do
          expect(mongoized.first).to be_a(Time)
        end

        it "converts the elements properly" do
          expect(mongoized.first).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
        end
      end

      context "when the input is a set" do
        let(:input) do
          [ date ].to_set
        end

        it "mongoizes to a set" do
          expect(mongoized).to be_a(Array)
        end

        it "converts the elements properly" do
          expect(mongoized.first).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
        end
      end
    end

    context "when the mongoizer creates duplicate elements" do
      let(:mongoized) do
        Set.mongoize(input)
      end

      before do
        expect(BigDecimal).to receive(:mongoize).exactly(4).times.and_wrap_original do |m, *args|
          1
        end
      end

      context "when the input is a set" do
        let(:input) do
          [ 1, 2, 3, 4 ].map(&:to_d).to_set
        end

        it "removes duplicates" do
          expect(mongoized).to eq([ 1 ])
        end
      end

      context "when the input is an array" do
        let(:input) do
          [ 1, 2, 3, 4 ].map(&:to_d)
        end

        it "removes duplicates" do
          expect(mongoized).to eq([ 1 ])
        end
      end
    end
  end
end
