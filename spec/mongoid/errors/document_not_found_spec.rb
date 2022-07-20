# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::DocumentNotFound do

  describe "#message" do

    context "when providing an id" do

      let(:error) do
        described_class.new(Person, 1, 1)
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "Document(s) not found for class Person with id(s) 1."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "When calling Person.find with an id or array of ids"
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          "Search for an id that is in the database or set the"
        )
      end
    end

    context "when providing ids" do

      let(:error) do
        described_class.new(Person, [ 1, 2, 3 ], [ 1 ])
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "Document(s) not found for class Person with id(s) 1."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "When calling Person.find with an id or array of ids"
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          "Search for an id that is in the database or set the"
        )
      end
    end

    context "when providing attributes" do

      let(:error) do
        described_class.new(Person, { name: "syd" }, nil)
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "Document not found for class Person with attributes {:name=>\"syd\"}."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "When calling Person.find_by with a hash of attributes"
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          "Search for attributes that are in the database or set"
        )
      end
    end

    context "when providing an _id and a shard key" do

      let(:id) { BSON::ObjectId.new }
      let(:doc) { { _id: id, a: "syd" } }
      let(:error) do
        described_class.new(Person, id, doc)
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "Document not found for class Person with id #{id.to_s} and shard key a: syd."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "When calling Person.find with an id and a shard key"
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          "Search for an id/shard key that is in the database or set"
        )
      end
    end

    context "when providing an id in a hash without a shard key" do

      let(:error) do
        described_class.new(Person, 1, { _id: 1 })
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "Document(s) not found for class Person with id(s) 1."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "When calling Person.find with an id or array of ids"
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          "Search for an id that is in the database or set the"
        )
      end
    end

    context "when not providing params or unmatched" do
      let(:error) do
        described_class.new(Person, nil, nil)
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "Could not find a document of class Person."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "Mongoid attempted to find a document of the class Person but none exist."
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          "Create a document of class Person or use a finder method that does not raise an exception when no documents are found."
        )
      end
    end
  end

  describe "#params" do

    let(:error) do
      described_class.new(Person, 1, 1)
    end

    it "returns the parameters passed to the find" do
      expect(error.params).to eq(1)
    end
  end

  describe "#klass" do

    let(:error) do
      described_class.new(Person, 1, 1)
    end

    it "returns the model class" do
      expect(error.klass).to eq(Person)
    end
  end
end
