require "spec_helper"

describe Mongoid::Factory do

  describe ".build" do

    context "when the type attribute is present" do

      let(:attributes) do
        { "_type" => "Person", "title" => "Sir" }
      end

      context "when the type is a class" do

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the type" do
          expect(person.title).to eq("Sir")
        end
      end

      context "when the type is a not a subclass" do

        let(:person) do
          described_class.build(Person, { "_type" => "Canvas" })
        end

        it "instantiates the provided class" do
          expect(person.class).to eq(Person)
        end
      end

      context "when the type is a subclass of the provided" do

        let(:person) do
          described_class.build(Person, { "_type" => "Doctor" })
        end

        it "instantiates the subclass" do
          expect(person.class).to eq(Doctor)
        end
      end

      context "when type is an empty string" do

        let(:attributes) do
          { "title" => "Sir", "_type" => "" }
        end

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the type" do
          expect(person.title).to eq("Sir")
        end
      end

      context "when type is the lower case class name" do

        let(:attributes) do
          { "title" => "Sir", "_type" => "person" }
        end

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the type" do
          expect(person.title).to eq("Sir")
        end
      end
    end

    context "when type is not preset" do

      let(:attributes) do
        { "title" => "Sir" }
      end

      let(:person) do
        described_class.build(Person, attributes)
      end

      it "instantiates based on the provided class" do
        expect(person.title).to eq("Sir")
      end
    end
  end

  describe ".from_db" do

    context "when the attributes are nil" do

      let(:document) do
        described_class.from_db(Address, nil)
      end

      it "generates based on the provided class" do
        expect(document).to be_a(Address)
      end

      it "sets the attributes to empty" do
        expect(document.attributes).to be_empty
      end
    end

    context "when a type is in the attributes" do

      context "when the type is a class" do

        let(:attributes) do
          { "_type" => "Person", "title" => "Sir" }
        end

        let(:document) do
          described_class.from_db(Address, attributes)
        end

        it "generates based on the type" do
          expect(document).to be_a(Person)
        end

        it "sets the attributes" do
          expect(document.title).to eq("Sir")
        end
      end

      context "when the type is empty" do

        let(:attributes) do
          { "_type" => "", "title" => "Sir" }
        end

        let(:document) do
          described_class.from_db(Person, attributes)
        end

        it "generates based on the provided class" do
          expect(document).to be_a(Person)
        end

        it "sets the attributes" do
          expect(document.title).to eq("Sir")
        end
      end

      context "when type is the lower case class name" do

        let(:attributes) do
          { "title" => "Sir", "_type" => "person" }
        end

        let(:person) do
          described_class.from_db(Person, attributes)
        end

        it "instantiates based on the type" do
          expect(person.title).to eq("Sir")
        end
      end
    end

    context "when a type is not in the attributes" do

      let(:attributes) do
        { "title" => "Sir" }
      end

      let(:document) do
        described_class.from_db(Person, attributes)
      end

      it "generates based on the provided class" do
        expect(document).to be_a(Person)
      end

      it "sets the attributes" do
        expect(document.title).to eq("Sir")
      end
    end
  end
end
