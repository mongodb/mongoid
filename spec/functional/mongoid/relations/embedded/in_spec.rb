require "spec_helper"

describe Mongoid::Relations::Embedded::In do

  before do
    Person.delete_all
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
          name.namable.should == person
        end

        it "sets the base on the inverse relation" do
          person.name.should == name
        end

        it "sets the same instance on the inverse relation" do
          person.name.should eql(name)
        end

        it "does not save the target" do
          person.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create(:ssn => "437-11-1112")
        end

        let(:name) do
          Name.new
        end

        before do
          name.namable = person
        end

        it "sets the target of the relation" do
          name.namable.should == person
        end

        it "sets the base on the inverse relation" do
          person.name.should == name
        end

        it "sets the same instance on the inverse relation" do
          person.name.should eql(name)
        end

        it "saves the base" do
          name.should be_persisted
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
          address.addressable.should == person
        end

        it "appends the base on the inverse relation" do
          person.addresses.should == [ address ]
        end

        it "sets the same instance in the inverse relation" do
          person.addresses.first.should eql(address)
        end

        it "does not save the target" do
          person.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let!(:person) do
          Person.create!(:ssn => "437-11-1112")
        end

        let(:address) do
          Address.new
        end

        before do
          address.addressable = person
        end

        it "sets the target of the relation" do
          address.addressable.should == person
        end

        it "sets the same instance in the inverse relation" do
          person.addresses.first.should eql(address)
        end

        it "appends the base on the inverse relation" do
          person.addresses.should == [ address ]
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
          name.namable.should be_nil
        end

        it "removes the inverse relation" do
          person.name.should be_nil
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
          name.namable.should be_nil
        end

        it "removes the inverse relation" do
          person.name.should be_nil
        end
      end

      context "when the documents are not new records" do

        let(:person) do
          Person.create(:ssn => "437-11-1112")
        end

        let(:name) do
          Name.new
        end

        before do
          name.namable = person
          name.namable = nil
        end

        it "sets the relation to nil" do
          name.namable.should be_nil
        end

        it "removed the inverse relation" do
          person.name.should be_nil
        end

        it "deletes the child document" do
          name.should be_destroyed
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
          address.addressable.should be_nil
        end

        it "removes the inverse relation" do
          person.addresses.should be_empty
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
          address.addressable.should be_nil
        end
      end

      context "when the documents are not new records" do

        let(:person) do
          Person.create(:ssn => "437-11-1112")
        end

        let(:address) do
          Address.new
        end

        before do
          address.addressable = person
          address.addressable = nil
        end

        it "sets the relation to nil" do
          address.addressable.should be_nil
        end

        it "removed the inverse relation" do
          person.addresses.should be_empty
        end

        it "deletes the child document" do
          address.should be_destroyed
        end
      end

      context "when a child already exists on the parent" do

        let(:person) do
          Person.create(:ssn => "437-11-1112")
        end

        let(:address_one) do
          Address.new
        end

        let(:address_two) do
          Address.new
        end

        before do
          person.addresses = [ address_one, address_two ]
          address_one.addressable = nil
        end

        it "sets the relation to nil" do
          address_one.addressable.should be_nil
        end

        it "removed the inverse relation" do
          person.addresses.should == [ address_two ]
        end

        it "deletes the child document" do
          address_one.should be_destroyed
        end

        it "reindexes the children" do
          address_two._index.should == 0
        end
      end
    end
  end

  context "when creating the tree through initialization" do

    let!(:person) do
      Person.create(:ssn => "666-66-6666")
    end

    let!(:address) do
      Address.create(:addressable => person)
    end

    let!(:first_location) do
      Location.create(:address => address)
    end

    let!(:second_location) do
      Location.create(:address => address)
    end

    it "saves the child" do
      Person.last.addresses.last.should == address
    end

    it "indexes the child" do
      address._index.should == 0
    end

    it "saves the first location with the correct index" do
      first_location._index.should == 0
    end

    it "saves the second location with the correct index" do
      second_location._index.should == 1
    end

    it "has the locations in the association array" do
      Person.last.addresses.last.locations.should ==
        [first_location, second_location]
    end
  end

  context "when instantiating a new child with a persisted parent" do

    let!(:person) do
      Person.create(:ssn => "666-66-6666")
    end

    let!(:address) do
      Address.new(:addressable => person)
    end

    let!(:location) do
      Location.new(:address => address)
    end

    it "does not save the child" do
      address.should_not be_persisted
    end

    it "does not save the deeply embedded children" do
      address.locations.first.should_not be_persisted
    end
  end

  context "when replacing the relation with another" do

    let!(:person) do
      Person.create(:ssn => "321-99-8888")
    end

    let!(:person_two) do
      Person.create(:ssn => "321-99-8889")
    end

    let!(:address) do
      person.addresses.create(:street => "Kotbusser Damm")
    end

    let!(:name) do
      person_two.create_name(:first_name => "Syd")
    end

    before do
      name.namable = address.addressable
      name.namable.save
    end

    it "sets the new parent" do
      name.namable.should eq(person)
    end

    it "removes the previous parent relation" do
      person_two.name.should be_nil
    end

    it "sets the new child relation" do
      person.name.should eq(name)
    end

    context "when reloading" do

      before do
        person.reload
      end

      it "sets the new parent" do
        name.namable.should eq(person)
      end

      it "removes the previous parent relation" do
        person_two.name.should be_nil
      end

      it "sets the new child relation" do
        person.name.should eq(name)
      end
    end
  end
end
