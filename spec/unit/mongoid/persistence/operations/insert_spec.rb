require "spec_helper"

describe Mongoid::Persistence::Operations::Insert do

  let(:document) do
    Patient.new(:title => "Mr")
  end

  let(:address) do
    Address.new(:street => "Oxford St")
  end

  let(:collection) do
    stub.quacks_like(Mongoid::Collection.allocate)
  end

  before do
    document.stubs(:collection).returns(collection)
  end

  describe "#initialize" do

    let(:insert) do
      described_class.new(document)
    end

    it "sets the document" do
      insert.document.should == document
    end

    it "sets the collection" do
      insert.collection.should == document.collection
    end

    it "defaults validation to true" do
      insert.should be_validating
    end

    it "sets the options" do
      insert.options.should ==
        { :safe => Mongoid.persist_in_safe_mode }
    end
  end

  describe "#persist" do

    def root_set_expectation
      lambda {
        collection.expects(:insert).with(
          document.raw_attributes,
          :safe => false
        ).returns("Object")
      }
    end

    def root_push_expectation
      lambda {
        collection.expects(:update).with(
          { "_id" => document.id },
          { "addresses" => { "$push" => address.raw_attributes } },
          :safe => false
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
        insert.persist.should == document
      end

      it "sets new_record to false" do
        root_set_expectation.call
        insert.persist
        document.new_record?.should == false
      end
    end

    context "when the document is not valid" do

      before do
        document.stubs(:valid?).returns(false)
      end

      it "returns the document" do
        insert.persist.should == document
      end

      it "leaves the document as a new record" do
        insert.persist
        document.new_record?.should == true
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
        document.new_record?.should == false
      end
    end
  end
end
