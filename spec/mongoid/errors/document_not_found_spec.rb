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
