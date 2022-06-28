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
  end
end
