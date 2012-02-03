require "spec_helper"

describe Mongoid::Persistence::Operations::Insert do

  before(:all) do
    Mongoid.identity_map_enabled = true
  end

  after(:all) do
    Mongoid.identity_map_enabled = false
  end

  let(:document) do
    Patient.new(title: "Mr")
  end

  let(:address) do
    Address.new(street: "Oxford St")
  end

  let(:collection) do
    stub.quacks_like(Moped::Collection.allocate)
  end

  let(:query) do
    stub
  end

  before do
    document.stubs(:collection).returns(collection)
  end

  describe "#persist" do

    context "when the insert succeeded" do

      let(:person) do
        Person.create
      end

      let(:in_map) do
        Mongoid::IdentityMap.get(Person, person.id)
      end

      it "puts the document in the identity map" do
        in_map.should eq(person)
      end
    end
  end

  describe "#initialize" do

    let(:insert) do
      described_class.new(document)
    end

    it "sets the document" do
      insert.document.should eq(document)
    end

    it "sets the collection" do
      insert.collection.should eq(document.collection)
    end

    it "defaults validation to true" do
      insert.should be_validating
    end

    it "sets the options" do
      insert.options.should be_empty
    end
  end

  describe "#persist" do

    def root_set_expectation
      ->{
        collection.expects(:insert).with(
          document.raw_attributes
        ).returns("Object")
      }
    end

    def root_push_expectation
      ->{
        collection.expects(:find).with({ "_id" => document.id }).returns(query)
        query.expects(:update).with(
          { "addresses" => { "$push" => address.raw_attributes } }
        ).returns("Object")
      }
    end

    let(:insert) do
      described_class.new(document)
    end

    context "when the document is valid" do

      it "inserts the new document" do
        root_set_expectation.call
        insert.persist
      end

      it "returns the document" do
        root_set_expectation.call
        insert.persist.should eq(document)
      end

      it "sets new_record to false" do
        root_set_expectation.call
        insert.persist
        document.new_record?.should be_false
      end
    end

    context "when the document is not valid" do

      before do
        document.stubs(:valid?).returns(false)
      end

      it "returns the document" do
        insert.persist.should eq(document)
      end

      it "leaves the document as a new record" do
        insert.persist
        document.new_record?.should be_true
      end
    end

    context "when not validating" do

      before do
        insert.instance_variable_set(:@validating, false)
      end

      after do
        insert.instance_variable_set(:@validating, true)
      end

      it "inserts the document in the database" do
        root_set_expectation.call
        insert.persist
        document.new_record?.should be_false
      end
    end
  end
end
