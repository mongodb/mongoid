# frozen_string_literal: true

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
      context "when using the default discriminator key" do
        let(:attributes) do
          { "title" => "Sir" }
        end

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the provided class" do
          expect(person.title).to eq("Sir")
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

      context "when using a custom discriminator key" do
        before do
          Person.discriminator_key = "dkey"
        end

        after do
          Person.discriminator_key = nil
        end

        let(:attributes) do
          { "title" => "Sir" }
        end

        let(:person) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the provided class" do
          expect(person.title).to eq("Sir")
        end

        context "when the type is a symbol" do

          let(:person) do
            described_class.build(Person, { :dkey => "Doctor" })
          end

          it "instantiates the subclass" do
            expect(person.class).to eq(Doctor)
          end
        end
      end

      context "when using a custom discriminator key and value" do
        before do
          Person.discriminator_key = "dkey"
          Doctor.discriminator_value = "dvalue"
        end

        after do
          Person.discriminator_key = nil
          Doctor.discriminator_value = nil
        end

        let(:attributes) do
          { "title" => "Sir", "dkey" => "dvalue" }
        end

        let(:doctor) do
          described_class.build(Person, attributes)
        end

        it "instantiates based on the provided class" do
          expect(doctor.title).to eq("Sir")
        end

        it "generates based on the provided class" do
          expect(doctor).to be_a(Person)
        end

        it "sets the attributes" do
          expect(doctor.title).to eq("Sir")
        end

        it "has the correct discriminator key/value" do
          expect(doctor.dkey).to eq("dvalue")
        end
      end
    end
  end

  describe ".from_db" do

    context "when the attributes are nil" do

      let(:document) do
        described_class.from_db(model_cls, nil)
      end

      context 'when model class does not use inheritance' do
        context 'when model overwrites _id field to not have a default' do
          let(:model_cls) { Idnodef }

          it "generates based on the provided class" do
            expect(document).to be_a(model_cls)
          end

          it "sets the attributes to empty" do
            expect(document.attributes).to be_empty
          end
        end

        context 'with default _id auto-assignment behavior' do
          let(:model_cls) { Agency }

          it "generates based on the provided class" do
            expect(document).to be_a(model_cls)
          end

          it "sets the attributes to generated _id only" do
            document.attributes.should == {'_id' => document.id}
          end
        end
      end

      context 'when model class is an inheritance root' do
        let(:model_cls) { Address }

        before do
          # Ensure a child is defined
          ShipmentAddress.superclass.should be model_cls
        end

        it "generates based on the provided class" do
          expect(document).to be_a(model_cls)
        end

        it "sets the attributes to _type only" do
          skip 'https://jira.mongodb.org/browse/MONGOID-5179'
          # Note that Address provides the _id override.
          document.attributes.should == {'_type' => 'Address'}
        end
      end

      context 'when model class is an inheritance leaf' do
        let(:model_cls) { ShipmentAddress }

        it "generates based on the provided class" do
          expect(document).to be_a(model_cls)
        end

        it "sets the attributes to empty" do
          # Note that Address provides the _id override.
          document.attributes.should == {'_type' => 'ShipmentAddress'}
        end
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

      context "when using the default discriminator key" do
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

      context "when using a custom discriminator key" do
        before do
          Person.discriminator_key = "dkey"
        end

        after do
          Person.discriminator_key = nil
        end

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

      context "when using a custom discriminator key and discriminator value" do
        before do
          Person.discriminator_key = "dkey"
          Person.discriminator_value = "dvalue"
        end

        after do
          Person.discriminator_key = nil
          Person.discriminator_value = nil
        end

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

        it "has the correct discriminator key/value" do
          expect(document.dkey).to eq("dvalue")
        end
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

    context 'when type does not correspond to a Class name with custom discriminator key' do

      before do
        Person.discriminator_key = "dkey"
      end

      after do
        Person.discriminator_key = nil
      end

      let(:attributes) do
        { "title" => "Sir", "dkey" => "invalid_class_name" }
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

    context 'when type does not correspond to a custom discriminator_value' do
      before do
        Person.discriminator_value = "dvalue"
      end

      after do
        Person.discriminator_value = nil
      end

      let(:attributes) do
        { "title" => "Sir", "_type" => "dvalue" }
      end

      let(:person) do
        described_class.from_db(Person, attributes)
      end

      it "generates based on the provided class" do
        expect(person).to be_a(Person)
      end

      it "sets the attributes" do
        expect(person.title).to eq("Sir")
      end

      it "has the correct discriminator key/value" do
        expect(person._type).to eq("dvalue")
      end
    end

    context 'when type is correct but the instantiation raises a NoMethodError' do
      class BadPerson < Person
        def self.instantiate_document(*args)
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

    context "when not deferring callbacks" do

      let(:person) do
        described_class.execute_from_db(Person, {}, execute_callbacks: true)
      end

      before do
        Person.set_callback :initialize, :after do |doc|
          doc.title = "Madam"
        end

        Person.set_callback :find, :after do |doc|
          doc.ssn = 1234
        end
      end

      after do
        Person.reset_callbacks(:initialize)
        Person.reset_callbacks(:find)
      end

      it "runs the initialize callbacks" do
        expect(person.title).to eq("Madam")
      end

      it "runs the find callbacks" do
        expect(person.ssn).to eq(1234)
      end
    end

    context "when deferring callbacks" do

      let(:person) do
        described_class.execute_from_db(Person, {}, nil, nil, execute_callbacks: false)
      end

      before do
        Person.set_callback :initialize, :after do |doc|
          doc.title = "Madam"
        end

        Person.set_callback :find, :after do |doc|
          doc.ssn = 1234
        end
      end

      after do
        Person.reset_callbacks(:initialize)
        Person.reset_callbacks(:find)
      end

      it "runs the initialize callbacks" do
        expect(person.title).to be nil
      end

      it "runs the find callbacks" do
        expect(person.ssn).to be nil
      end
    end
  end
end
