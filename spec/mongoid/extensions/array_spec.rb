# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Extensions::Array do

  describe "#__evolve_object_id__" do

    context "when provided an array of strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:other) do
        "blah"
      end

      let(:array) do
        [ object_id.to_s, other ]
      end

      let(:evolved) do
        array.__evolve_object_id__
      end

      it "converts the convertible ones to object ids" do
        expect(evolved).to eq([ object_id, other ])
      end

      it "returns the same instance" do
        expect(evolved).to equal(array)
      end
    end

    context "when provided an array of object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:array) do
        [ object_id ]
      end

      let(:evolved) do
        array.__evolve_object_id__
      end

      it "returns the array" do
        expect(evolved).to eq(array)
      end

      it "returns the same instance" do
        expect(evolved).to equal(array)
      end
    end

    context "when some values are nil" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:array) do
        [ object_id, nil ]
      end

      let(:evolved) do
        array.__evolve_object_id__
      end

      it "returns the array with the nils" do
        expect(evolved).to eq([ object_id, nil ])
      end

      it "returns the same instance" do
        expect(evolved).to equal(array)
      end
    end

    context "when some values are empty strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:array) do
        [ object_id, "" ]
      end

      let(:evolved) do
        array.__evolve_object_id__
      end

      it "returns the array with the empty strings" do
        expect(evolved).to eq([ object_id, "" ])
      end

      it "returns the same instance" do
        expect(evolved).to equal(array)
      end
    end
  end

  describe "#__mongoize_object_id__" do

    context "when provided an array of strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:other) do
        "blah"
      end

      let(:array) do
        [ object_id.to_s, other ]
      end

      let(:mongoized) do
        array.__mongoize_object_id__
      end

      it "converts the convertible ones to object ids" do
        expect(mongoized).to eq([ object_id, other ])
      end

      it "returns the same instance" do
        expect(mongoized).to equal(array)
      end
    end

    context "when provided an array of object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:array) do
        [ object_id ]
      end

      let(:mongoized) do
        array.__mongoize_object_id__
      end

      it "returns the array" do
        expect(mongoized).to eq(array)
      end

      it "returns the same instance" do
        expect(mongoized).to equal(array)
      end
    end

    context "when some values are nil" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:array) do
        [ object_id, nil ]
      end

      let(:mongoized) do
        array.__mongoize_object_id__
      end

      it "returns the array without the nils" do
        expect(mongoized).to eq([ object_id ])
      end

      it "returns the same instance" do
        expect(mongoized).to equal(array)
      end
    end

    context "when some values are empty strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:array) do
        [ object_id, "" ]
      end

      let(:mongoized) do
        array.__mongoize_object_id__
      end

      it "returns the array without the empty strings" do
        expect(mongoized).to eq([ object_id ])
      end

      it "returns the same instance" do
        expect(mongoized).to equal(array)
      end
    end
  end

  describe "#__mongoize_time__" do

    let(:array) do
      [ 2010, 11, 19, 00, 24, 49.123457 ]
    end

    let(:mongoized) do
      array.__mongoize_time__
    end

    context "when setting ActiveSupport time zone" do
      include_context 'setting ActiveSupport time zone'

      # In AS time zone (could be different from Ruby time zone)
      let(:expected_time) { ::Time.zone.local(*array).in_time_zone }

      it "converts to the as time zone" do
        expect(mongoized.zone).to eq("JST")
      end

      it_behaves_like 'mongoizes to AS::TimeWithZone'
      it_behaves_like 'maintains precision when mongoized'
    end
  end

  describe "#delete_one" do

    context "when the object doesn't exist" do

      let(:array) do
        []
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "returns nil" do
        expect(deleted).to be_nil
      end
    end

    context "when the object exists once" do

      let(:array) do
        [ "1", "2" ]
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "deletes the object" do
        expect(array).to eq([ "2" ])
      end

      it "returns the object" do
        expect(deleted).to eq("1")
      end
    end

    context "when the object exists more than once" do

      let(:array) do
        [ "1", "2", "1" ]
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "deletes the first object" do
        expect(array).to eq([ "2", "1" ])
      end

      it "returns the object" do
        expect(deleted).to eq("1")
      end
    end
  end

  describe ".demongoize" do

    let(:array) do
      [ 1, 2, 3 ]
    end

    it "returns the array" do
      expect(Array.demongoize(array)).to eq(array)
    end
  end

  describe ".mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:input) do
      [ date ]
    end

    let(:mongoized) do
      Array.mongoize(input)
    end

    it "mongoizes each element in the array" do
      expect(mongoized.first).to be_a(Time)
    end

    it "converts the elements properly" do
      expect(mongoized.first).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
    end

    context "when passing in a set" do
      let(:input) do
        [ date ].to_set
      end

      it "mongoizes to an array" do
        expect(mongoized).to be_a(Array)
      end

      it "converts the elements properly" do
        expect(mongoized.first).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
      end
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:array) do
      [ date ]
    end

    let(:mongoized) do
      array.mongoize
    end

    it "mongoizes each element in the array" do
      expect(mongoized.first).to be_a(Time)
    end

    it "converts the elements properly" do
      expect(mongoized.first).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
    end
  end

  describe ".resizable?" do

    it "returns true" do
      expect(Array).to be_resizable
    end
  end

  describe "#resiable?" do

    it "returns true" do
      expect([]).to be_resizable
    end
  end
end
