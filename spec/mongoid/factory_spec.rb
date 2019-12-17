# frozen_string_literal: true
# encoding: utf-8

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

      context "when the type is aliased subclass of the provider" do
        Doctor.override_inheritance_type_value "Bones"

        let(:person) do
          described_class.build(Person, { "_type" => "Bones" })
        end

        it "instantiates the subclass" do
          expect(person.class).to eq(Doctor)
        end
      end

      context "when the type is aliased subclass of the provider and alias is not camelized" do
        Doctor.override_inheritance_type_value "bones"

        let(:person) do
          described_class.build(Person, { "_type" => "bones" })
        end

        it "instantiates the subclass" do
          expect(person.class).to eq(Doctor)
        end
      end

      context "additional levels of subclassing" do
        class Specialist < Doctor
          override_inheritance_type_value 'bones'
        end

        class Nephrologist < Specialist; end

        let(:doctor) do
          described_class.build(Person, { "_type" => "bones" })
        end

        it "instantiates the subclass" do
          expect(doctor.class).to eq(Doctor)
        end

        let(:nephrologist) do
          described_class.build(Person, { "_type" => "Nephrologist"})
        end

        it "instantiates the second level subclass" do
          expect(nephrologist.class).to eq(Nephrologist)
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

      context "when type is aliased subclass name" do
        Doctor.override_inheritance_type_value 'Bones'

        let(:attributes) do
          { "title" => "Sir", "_type" => "Bones" }
        end

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "uses the subclass alias for type" do
          expect(person._type).to eq("Bones")
        end

        it "instantiates the subclass" do
          expect(person.class).to eq(Doctor)
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

    context "when the type is a symbol" do

      let(:person) do
        described_class.build(Person, { :_type => "Doctor" })
      end

      it "instantiates the subclass" do
        expect(person.class).to eq(Doctor)
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

    context 'when type does not correspond to a Class name' do

      let(:attributes) do
        { "title" => "Sir", "_type" => "invalid_class_name" }
      end

      let(:person) do
        described_class.from_db(Person, attributes)
      end

      it 'raises a exception' do
        expect {
          person
        }.to raise_exception(Mongoid::Errors::UnknownModel)
      end

    end

    context 'when type is correct but the instantiation raises a NoMethodError' do
      class BadPerson < Person
        def self.instantiate(*args)
          call_some_nonexistent_method(*args)
          super
        end
      end

      let(:attributes) do
        { "title" => "Sir", "_type" => "BadPerson" }
      end

      let(:person) do
        described_class.from_db(BadPerson, attributes)
      end

      it 'raises a exception' do
        expect {
          person
        }.to raise_exception(NoMethodError)
      end

    end
  end
end
