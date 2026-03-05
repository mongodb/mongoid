# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Extensions::Symbol do

  [ :mongoize, :demongoize ].each do |method|

    describe ".mongoize" do

      context "when the object is not a symbol" do

        it "returns the symbol" do
          expect(Symbol.send(method, "test")).to eq(:test)
        end
      end

      context "when the object is nil" do

        it "returns nil" do
          expect(Symbol.send(method, nil)).to be_nil
        end
      end

      context "when the object is uncastable" do

        it "returns nil" do
          expect(Symbol.send(method, [])).to be_nil
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(:test.mongoize).to eq(:test)
    end
  end
end
