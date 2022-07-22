# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Symbol do

  describe "#mongoid_id?" do

    context "when the string is id" do

      it "returns true" do
        expect(:id).to be_mongoid_id
      end
    end

    context "when the string is _id" do

      it "returns true" do
        expect(:_id).to be_mongoid_id
      end
    end

    context "when the string contains id" do

      it "returns false" do
        expect(:identity).to_not be_mongoid_id
      end
    end

    context "when the string contains _id" do

      it "returns false" do
        expect(:something_id).to_not be_mongoid_id
      end
    end
  end

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
