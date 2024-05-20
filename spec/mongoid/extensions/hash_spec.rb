# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Extensions::Hash do

  describe "#__evolve_object_id__" do

    context "when values have object id strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id.to_s }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "converts each value in the hash" do
        expect(evolved[:field]).to eq(object_id)
      end
    end

    context "when values have object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "converts each value in the hash" do
        expect(evolved[:field]).to eq(object_id)
      end
    end

    context "when values have empty strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: "" }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "retains the empty string values" do
        expect(evolved[:field]).to be_empty
      end
    end

    context "when values have nils" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: nil }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "retains the nil values" do
        expect(evolved[:field]).to be_nil
      end
    end
  end

  describe "#__mongoize_object_id__" do

    context "when values have object id strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id.to_s }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts each value in the hash" do
        expect(mongoized[:field]).to eq(object_id)
      end
    end

    context "when values have object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts each value in the hash" do
        expect(mongoized[:field]).to eq(object_id)
      end
    end

    context "when values have empty strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: "" }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts the empty strings to nil" do
        expect(mongoized[:field]).to be_nil
      end
    end

    context "when values have nils" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: nil }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "retains the nil values" do
        expect(mongoized[:field]).to be_nil
      end
    end
  end

  describe ".demongoize" do

    let(:hash) do
      { field: 1 }
    end

    it "returns the hash" do
      expect(Hash.demongoize(hash)).to eq(hash)
    end

    context "when object is nil" do
      let(:demongoized) do
        Hash.demongoize(nil)
      end

      it "returns nil" do
        expect(demongoized).to be_nil
      end
    end

    context "when the object is uncastable" do
      let(:demongoized) do
        Hash.demongoize(1)
      end

      it "returns the object" do
        expect(demongoized).to eq(1)
      end
    end
  end

  describe ".mongoize" do

    context "when object isn't nil" do

      let(:date) do
        Date.new(2012, 1, 1)
      end

      let(:hash) do
        { date: date }
      end

      let(:mongoized) do
        Hash.mongoize(hash)
      end

      it "mongoizes each element in the hash" do
        expect(mongoized[:date]).to be_a(Time)
      end

      it "converts the elements properly" do
        expect(mongoized[:date]).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
      end

      it "mongoizes to a BSON::Document" do
        expect(mongoized).to be_a(BSON::Document)
      end
    end

    context "when object is nil" do
      let(:mongoized) do
        Hash.mongoize(nil)
      end

      it "returns nil" do
        expect(mongoized).to be_nil
      end
    end

    context "when the object is uncastable" do
      let(:mongoized) do
        Hash.mongoize(1)
      end

      it "returns nil" do
        expect(mongoized).to be_nil
      end
    end

    describe "when mongoizing a BSON::Document" do
      let(:mongoized) do
        Hash.mongoize(BSON::Document.new({ x: 1, y: 2 }))
      end

      it "returns the same hash" do
        expect(mongoized).to eq({ "x" => 1, "y" => 2 })
      end

      it "returns a BSON::Document" do
        expect(mongoized).to be_a(BSON::Document)
      end
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:hash) do
      { date: date }
    end

    let(:mongoized) do
      hash.mongoize
    end

    it "mongoizes each element in the hash" do
      expect(mongoized[:date]).to be_a(Time)
    end

    it "converts the elements properly" do
      expect(mongoized[:date]).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
    end
  end

  describe "#resizable?" do

    it "returns true" do
      expect({}).to be_resizable
    end
  end

  describe ".resizable?" do

    it "returns true" do
      expect(Hash).to be_resizable
    end
  end
end
