# frozen_string_literal: true

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

  describe ".__mongoize_fk__" do

    context "when the related model uses object ids" do

      let(:association) do
        Person.relations["preferences"]
      end

      context "when provided an object id" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:fk) do
          Array.__mongoize_fk__(association, object_id)
        end

        it "returns the object id as an array" do
          expect(fk).to eq([ object_id ])
        end
      end

      context "when provided a object ids" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:fk) do
          Array.__mongoize_fk__(association, [ object_id ])
        end

        it "returns the object ids" do
          expect(fk).to eq([ object_id ])
        end
      end

      context "when provided a string" do

        context "when the string is a legal object id" do

          let(:object_id) do
            BSON::ObjectId.new
          end

          let(:fk) do
            Array.__mongoize_fk__(association, object_id.to_s)
          end

          it "returns the object id in an array" do
            expect(fk).to eq([ object_id ])
          end
        end

        context "when the string is not a legal object id" do

          let(:string) do
            "blah"
          end

          let(:fk) do
            Array.__mongoize_fk__(association, string)
          end

          it "returns the string in an array" do
            expect(fk).to eq([ string ])
          end
        end

        context "when the string is blank" do

          let(:fk) do
            Array.__mongoize_fk__(association, "")
          end

          it "returns an empty array" do
            expect(fk).to be_empty
          end
        end
      end

      context "when provided nil" do

        let(:fk) do
          Array.__mongoize_fk__(association, nil)
        end

        it "returns an empty array" do
          expect(fk).to be_empty
        end
      end

      context "when provided an array of strings" do

        context "when the strings are legal object ids" do

          let(:object_id) do
            BSON::ObjectId.new
          end

          let(:fk) do
            Array.__mongoize_fk__(association, [ object_id.to_s ])
          end

          it "returns the object id in an array" do
            expect(fk).to eq([ object_id ])
          end
        end

        context "when the strings are not legal object ids" do

          let(:string) do
            "blah"
          end

          let(:fk) do
            Array.__mongoize_fk__(association, [ string ])
          end

          it "returns the string in an array" do
            expect(fk).to eq([ string ])
          end
        end

        context "when the strings are blank" do

          let(:fk) do
            Array.__mongoize_fk__(association, [ "", "" ])
          end

          it "returns an empty array" do
            expect(fk).to be_empty
          end
        end
      end

      context "when provided nils" do

        let(:fk) do
          Array.__mongoize_fk__(association, [ nil, nil, nil ])
        end

        it "returns an empty array" do
          expect(fk).to be_empty
        end
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

    context "when using active support's time zone" do
      include_context 'using AS time zone'

      # In AS time zone (could be different from Ruby time zone)
      let(:expected_time) { ::Time.zone.local(*array).in_time_zone }

      it "converts to the as time zone" do
        expect(mongoized.zone).to eq("JST")
      end

      it_behaves_like 'mongoizes to AS::TimeWithZone'
      it_behaves_like 'maintains precision when mongoized'
    end

    context "when not using active support's time zone" do
      include_context 'not using AS time zone'

      # In Ruby time zone (could be different from AS time zone)
      let(:expected_time) { ::Time.local(*array).in_time_zone }

      it_behaves_like 'mongoizes to Time'
      it_behaves_like 'maintains precision when mongoized'
    end
  end

  describe "#blank_criteria?" do

    context "when the array has an empty _id criteria" do

      context "when only the id criteria is in the array" do

        let(:array) do
          [{ "_id" => { "$in" => [] }}]
        end

        it "is false" do
          expect(array.blank_criteria?).to be false
        end
      end

      context "when the id criteria is in the array with others" do

        let(:array) do
          [{ "_id" => "test" }, { "_id" => { "$in" => [] }}]
        end

        it "is false" do
          expect(array.blank_criteria?).to be false
        end
      end
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

  describe "#multi_arged?" do

    context "when there are multiple elements" do

      let(:array) do
        [ 1, 2, 3 ]
      end

      it "returns true" do
        expect(array).to be_multi_arged
      end
    end

    context "when there is one element" do

      context "when the element is a non enumerable" do

        let(:array) do
          [ 1 ]
        end

        it "returns false" do
          expect(array).to_not be_multi_arged
        end
      end

      context "when the element is resizable Hash instance" do

        let(:array) do
          [{'key' => 'value'}]
        end

        it "returns false" do
          expect(array).to_not be_multi_arged
        end
      end

      context "when the element is array of resizable Hash instances" do

        let(:array) do
          [[{'key1' => 'value2'},{'key1' => 'value2'}]]
        end

        it "returns true" do
          expect(array).to be_multi_arged
        end
      end

      context "when the element is an array" do

        let(:array) do
          [[ 1 ]]
        end

        it "returns true" do
          expect(array).to be_multi_arged
        end
      end

      context "when the element is a range" do

        let(:array) do
          [ 1..2 ]
        end

        it "returns true" do
          expect(array).to be_multi_arged
        end
      end
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
