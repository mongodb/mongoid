require "spec_helper"

describe Mongoid::Relations::Embedded::In do

  describe "#===" do

    let(:base) do
      Name.new
    end

    let(:target) do
      Person.new
    end

    let(:metadata) do
      Name.relations["namable"]
    end

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    context "when the proxied document is same class" do

      context "when the document is a different instance" do

        it "returns false" do
          expect((relation === Person.new)).to be false
        end
      end

      context "when the document is the same instance" do

        it "returns true" do
          expect((relation === target)).to be true
        end
      end
    end
  end

  describe "#=" do

    context "when the inverse of an embeds one" do

      context "when the child is a new record" do

        let(:person) do
          Person.new
        end

        let(:name) do
          Name.new
        end

        before do
          name.namable = person
        end

        it "sets the target of the relation" do
          expect(name.namable).to eq(person)
        end

        it "sets the base on the inverse relation" do
          expect(person.name).to eq(name)
        end

        it "sets the same instance on the inverse relation" do
          expect(person.name).to eql(name)
        end

        it "does not save the target" do
          expect(person).to_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let(:name) do
          Name.new
        end

        before do
          name.namable = person
        end

        it "sets the target of the relation" do
          expect(name.namable).to eq(person)
        end

        it "sets the base on the inverse relation" do
          expect(person.name).to eq(name)
        end

        it "sets the same instance on the inverse relation" do
          expect(person.name).to eql(name)
        end

        it "does not save the base" do
          expect(name).to_not be_persisted
        end
      end
    end

    context "when the inverse of an embeds many" do

      context "when the child is a new record" do

        let(:person) do
          Person.new
        end

        let(:address) do
          Address.new
        end

        before do
          address.addressable = person
        end

        it "sets the target of the relation" do
          expect(address.addressable).to eq(person)
        end

        it "appends the base on the inverse relation" do
          expect(person.addresses).to eq([ address ])
        end

        it "sets the same instance in the inverse relation" do
          expect(person.addresses.first).to eql(address)
        end

        it "does not save the target" do
          expect(person).to_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let!(:person) do
          Person.create!
        end

        let(:address) do
          Address.new
        end

        before do
          address.addressable = person
        end

        it "sets the target of the relation" do
          expect(address.addressable).to eq(person)
        end

        it "sets the same instance in the inverse relation" do
          expect(person.addresses.first).to eql(address)
        end

        it "appends the base on the inverse relation" do
          expect(person.addresses).to eq([ address ])
        end
      end
    end
  end

  describe "#= nil" do

    context "when the inverse of an embeds one" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:name) do
          Name.new
        end

        before do
          name.namable = person
          name.namable = nil
        end

        it "sets the relation to nil" do
          expect(name.namable).to be_nil
        end

        it "removes the inverse relation" do
          expect(person.name).to be_nil
        end
      end

      context "when the inverse is already nil" do

        let(:person) do
          Person.new
        end

        let(:name) do
          Name.new
        end

        before do
          name.namable = nil
        end

        it "sets the relation to nil" do
          expect(name.namable).to be_nil
        end

        it "removes the inverse relation" do
          expect(person.name).to be_nil
        end
      end

      context "when the documents are not new records" do

        let(:person) do
          Person.create
        end

        let(:name) do
          Name.new
        end

        before do
          name.namable = person
          name.namable = nil
        end

        it "sets the relation to nil" do
          expect(name.namable).to be_nil
        end

        it "removed the inverse relation" do
          expect(person.name).to be_nil
        end

        it "deletes the child document" do
          expect(name).to be_destroyed
        end
      end
    end

    context "when the inverse of an embeds many" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:address) do
          Address.new
        end

        before do
          address.addressable = person
          address.addressable = nil
        end

        it "sets the relation to nil" do
          expect(address.addressable).to be_nil
        end

        it "removes the inverse relation" do
          expect(person.addresses).to be_empty
        end
      end

      context "when the inverse is already nil" do

        let(:address) do
          Address.new
        end

        before do
          address.addressable = nil
        end

        it "sets the relation to nil" do
          expect(address.addressable).to be_nil
        end
      end

      context "when the documents are not new records" do

        let(:person) do
          Person.create
        end

        let(:address) do
          Address.new
        end

        before do
          address.addressable = person
          address.addressable = nil
        end

        it "sets the relation to nil" do
          expect(address.addressable).to be_nil
        end

        it "removed the inverse relation" do
          expect(person.addresses).to be_empty
        end

        it "deletes the child document" do
          expect(address).to be_destroyed
        end
      end

      context "when a child already exists on the parent" do

        let(:person) do
          Person.create
        end

        let(:address_one) do
          Address.new(street: "first")
        end

        let(:address_two) do
          Address.new(street: "second")
        end

        before do
          person.addresses = [ address_one, address_two ]
          address_one.addressable = nil
        end

        it "sets the relation to nil" do
          expect(address_one.addressable).to be_nil
        end

        it "removed the inverse relation" do
          expect(person.addresses).to eq([ address_two ])
        end

        it "deletes the child document" do
          expect(address_one).to be_destroyed
        end

        it "reindexes the children" do
          expect(address_two._index).to eq(0)
        end
      end
    end
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Embedded::In
    end

    let(:base) do
      Name.new
    end

    let(:target) do
      Person.new
    end

    let(:metadata) do
      Name.relations["namable"]
    end

    it "returns the embedded one builder" do
      expect(described_class.builder(base, metadata, target)).to be_a(builder_klass)
    end
  end

  describe ".embedded?" do

    it "returns true" do
      expect(described_class).to be_embedded
    end
  end

  describe ".foreign_key_suffix" do

    it "returns nil" do
      expect(described_class.foreign_key_suffix).to be_nil
    end
  end

  describe ".macro" do

    it "returns embeds_one" do
      expect(described_class.macro).to eq(:embedded_in)
    end
  end

  describe ".nested_builder" do

    let(:nested_builder_klass) do
      Mongoid::Relations::Builders::NestedAttributes::One
    end

    let(:metadata) do
      Name.relations["namable"]
    end

    let(:attributes) do
      {}
    end

    it "returns the single nested builder" do
      expect(described_class.nested_builder(metadata, attributes, {})).to be_a(nested_builder_klass)
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let!(:name) do
      person.build_name(first_name: "Tony")
    end

    let(:document) do
      name.namable
    end

    Mongoid::Document.public_instance_methods(true).each do |method|

      context "when checking #{method}" do

        it "returns true" do
          expect(document.respond_to?(method)).to be true
        end
      end
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      expect(described_class.valid_options).to eq(
        [ :autobuild, :cyclic, :polymorphic, :touch ]
      )
    end
  end

  describe ".validation_default" do

    it "returns false" do
      expect(described_class.validation_default).to be false
    end
  end

  context "when creating the tree through initialization" do

    let!(:person) do
      Person.create
    end

    let!(:address) do
      Address.create(addressable: person)
    end

    let!(:first_location) do
      Location.create(address: address)
    end

    let!(:second_location) do
      Location.create(address: address)
    end

    it "saves the child" do
      expect(Person.last.addresses.last).to eq(address)
    end

    it "indexes the child" do
      expect(address._index).to eq(0)
    end

    it "saves the first location with the correct index" do
      expect(first_location._index).to eq(0)
    end

    it "saves the second location with the correct index" do
      expect(second_location._index).to eq(1)
    end

    it "has the locations in the association array" do
      expect(Person.last.addresses.last.locations).to eq(
        [first_location, second_location]
      )
    end
  end

  context "when instantiating a new child with a persisted parent" do

    let!(:person) do
      Person.create
    end

    let!(:address) do
      Address.new(addressable: person)
    end

    let!(:location) do
      Location.new(address: address)
    end

    it "does not save the child" do
      expect(address).to_not be_persisted
    end

    it "does not save the deeply embedded children" do
      expect(address.locations.first).to_not be_persisted
    end
  end

  context "when replacing the relation with another" do

    let!(:person) do
      Person.create
    end

    let!(:person_two) do
      Person.create
    end

    let!(:address) do
      person.addresses.create(street: "Kotbusser Damm")
    end

    let!(:name) do
      person_two.create_name(first_name: "Syd")
    end

    before do
      name.namable = address.addressable
      name.namable.save
    end

    it "sets the new parent" do
      expect(name.namable).to eq(person)
    end

    it "removes the previous parent relation" do
      expect(person_two.name).to be_nil
    end

    it "sets the new child relation" do
      expect(person.name).to eq(name)
    end

    context "when reloading" do

      before do
        person.reload
      end

      it "sets the new parent" do
        expect(name.namable).to eq(person)
      end

      it "removes the previous parent relation" do
        expect(person_two.name).to be_nil
      end

      it "sets the new child relation" do
        expect(person.name).to eq(name)
      end
    end
  end
end
