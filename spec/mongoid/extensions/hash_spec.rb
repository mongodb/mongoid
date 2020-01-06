# frozen_string_literal: true
# encoding: utf-8

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

  describe "#__consolidate__" do

    context "when the hash already contains the key" do

      context "when the $set is first" do

        let(:hash) do
          { "$set" => { name: "Tool" }, likes: 10, "$inc" => { plays: 1 }}
        end

        let(:consolidated) do
          hash.__consolidate__(Band)
        end

        it "moves the non hash values under the provided key" do
          expect(consolidated).to eq({
            "$set" => { name: "Tool", likes: 10 }, "$inc" => { plays: 1 }
          })
        end
      end

      context "when the $set is not first" do

        let(:hash) do
          { likes: 10, "$inc" => { plays: 1 }, "$set" => { name: "Tool" }}
        end

        let(:consolidated) do
          hash.__consolidate__(Band)
        end

        it "moves the non hash values under the provided key" do
          expect(consolidated).to eq({
            "$set" => { likes: 10, name: "Tool" }, "$inc" => { plays: 1 }
          })
        end
      end
    end

    context "when the hash does not contain the key" do

      let(:hash) do
        { likes: 10, "$inc" => { plays: 1 }, name: "Tool"}
      end

      let(:consolidated) do
        hash.__consolidate__(Band)
      end

      it "moves the non hash values under the provided key" do
        expect(consolidated).to eq({
          "$set" => { likes: 10, name: "Tool" }, "$inc" => { plays: 1 }
        })
      end
    end
  end

  context "when the hash key is a string" do

    let(:hash) do
      { "100" => { "name" => "hundred" } }
    end

    let(:nested) do
      hash.__nested__("100.name")
    end

    it "should retrieve a nested value under the provided key" do
      expect(nested).to eq "hundred"
    end

    context 'and the value is falsey' do
      let(:hash) do
        { "100" => { "name" => false } }
      end
      it "should retrieve the falsey nested value under the provided key" do
        expect(nested).to eq false
      end
    end

    context 'and the value is nil' do
      let(:hash) do
        { "100" => { 0 => "Please don't return this value!" } }
      end
      it "should retrieve the nil nested value under the provided key" do
        expect(nested).to eq nil
      end
    end
  end

  context "when the hash key is an integer" do
    let(:hash) do
      { 100 => { "name" => "hundred" } }
    end

    let(:nested) do
      hash.__nested__("100.name")
    end

    it "should retrieve a nested value under the provided key" do
      expect(nested).to eq("hundred")
    end
  end

  context "when the parent key is not present" do

    let(:hash) do
      { "101" => { "name" => "hundred and one" } }
    end

    let(:nested) do
      hash.__nested__("100.name")
    end

    it "should return nil" do
      expect(nested).to eq(nil)
    end
  end

  describe ".demongoize" do

    let(:hash) do
      { field: 1 }
    end

    it "returns the hash" do
      expect(Hash.demongoize(hash)).to eq(hash)
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
    end

    context "when object is nil" do
      let(:mongoized) do
        Hash.mongoize(nil)
      end

      it "returns nil" do
        expect(mongoized).to be_nil
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

  shared_examples_for 'unsatisfiable criteria method' do

    context "when the hash has only an empty _id criteria" do

      let(:hash) do
        { "_id" => { "$in" => [] }}
      end

      it "is true" do
        expect(hash.send(meth)).to be true
      end
    end

    context "when the hash has an empty _id criteria and another criteria" do

      let(:hash) do
        { "_id" => { "$in" => [] }, 'foo' => 'bar'}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end

    context "when the hash has an empty _id criteria via $and" do

      let(:hash) do
        {'$and' => [{ "_id" => { "$in" => [] }}]}
      end

      it "is true" do
        expect(hash.send(meth)).to be true
      end
    end

    context "when the hash has an empty _id criteria via $and and another criteria at top level" do

      let(:hash) do
        {'$and' => [{ "_id" => { "$in" => [] }}], 'foo' => 'bar'}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end

    context "when the hash has an empty _id criteria via $and and another criteria in $and" do

      let(:hash) do
        {'$and' => [{ "_id" => { "$in" => [] }}, {'foo' => 'bar'}]}
      end

      it "is true" do
        expect(hash.send(meth)).to be true
      end
    end

    context "when the hash has an empty _id criteria via $and and another criteria in $and value" do

      let(:hash) do
        {'$and' => [{ "_id" => { "$in" => [] }, 'foo' => 'bar'}]}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end

    context "when the hash has an empty _id criteria via $or" do

      let(:hash) do
        {'$or' => [{ "_id" => { "$in" => [] }}]}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end

    context "when the hash has an empty _id criteria via $nor" do

      let(:hash) do
        {'$nor' => [{ "_id" => { "$in" => [] }}]}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end
  end

  describe "#blank_criteria?" do
    let(:meth) { :blank_criteria? }

    it_behaves_like 'unsatisfiable criteria method'
  end

  describe "#_mongoid_unsatisfiable_criteria?" do
    let(:meth) { :_mongoid_unsatisfiable_criteria? }

    it_behaves_like 'unsatisfiable criteria method'
  end
end
