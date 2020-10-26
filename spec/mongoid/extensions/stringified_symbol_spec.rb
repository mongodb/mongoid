# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Extensions::StringifiedSymbol do

  describe ".demongoize" do

    context "when the object is not a symbol" do

      it "returns the symbol" do
        expect(Mongoid::Extensions::StringifiedSymbol.demongoize("test")).to eq(:test)
      end
    end

    context "when the object is a symbol" do

      it "returns the symbol" do
        expect(Mongoid::Extensions::StringifiedSymbol.demongoize(:test)).to eq(:test)
      end
    end

    context "when the object is a BSON Symbol" do

      it "returns a symbol" do
        expect(Mongoid::Extensions::StringifiedSymbol.demongoize(BSON::Symbol::Raw.new(:test))).to eq(:test)
      end
    end


    context "when the object cannot be converted" do

      it "returns nil" do
        expect(Mongoid::Extensions::StringifiedSymbol.demongoize(14)).to be_nil
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        expect(Mongoid::Extensions::StringifiedSymbol.demongoize(nil)).to be_nil
      end
    end
  end

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

  describe ".mongoize" do

    context "when the object is not a symbol" do

      it "returns the object" do
        expect(Mongoid::Extensions::StringifiedSymbol.mongoize("test")).to eq("test")
      end
    end

    context "when the object is a symbol" do

      it "returns a string" do
        expect(Mongoid::Extensions::StringifiedSymbol.mongoize(:test)).to eq("test")
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        expect(Mongoid::Extensions::StringifiedSymbol.mongoize(nil)).to be_nil
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(:test.mongoize).to eq(:test)
    end
  end
end
