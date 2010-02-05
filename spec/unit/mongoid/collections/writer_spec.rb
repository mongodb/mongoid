require "spec_helper"

describe Mongoid::Collections::Writer do

  let(:master) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  let(:master_collection) do
    stub.quacks_like(Mongo::Collection.allocate)
  end

  let(:writer) do
    Mongoid::Collections::Writer.new(master, "people")
  end

  before do
    master.expects(:collection).with("people").returns(master_collection)
  end

  describe "#<<" do

    before do
      master_collection.expects(:<<).with("test")
    end

    it "delegates to the next collection" do
      writer.<< "test"
    end
  end

  describe "#create_index" do

    before do
      master_collection.expects(:create_index).with(:test)
    end

    it "delegates to the next collection" do
      writer.create_index(:test)
    end
  end

  describe "#drop" do

    before do
      master_collection.expects(:drop)
    end

    it "delegates to the next collection" do
      writer.drop
    end
  end

  describe "#drop_index" do

    before do
      master_collection.expects(:drop_index)
    end

    it "delegates to the next collection" do
      writer.drop_index
    end
  end

  describe "#drop_indexes" do

    before do
      master_collection.expects(:drop_indexes)
    end

    it "delegates to the next collection" do
      writer.drop_indexes
    end
  end

  describe "#initialize" do

    it "sets the mongo collection" do
      writer.collection.should == master_collection
    end

  end

  describe "#insert" do

    before do
      master_collection.expects(:insert).with({})
    end

    it "delegates to the next collection" do
      writer.insert({})
    end
  end

  describe "#remove" do

    before do
      master_collection.expects(:remove)
    end

    it "delegates to the next collection" do
      writer.remove
    end
  end

  describe "#rename" do

    before do
      master_collection.expects(:rename)
    end

    it "delegates to the next collection" do
      writer.rename
    end
  end

  describe "#save" do

    before do
      master_collection.expects(:save)
    end

    it "delegates to the next collection" do
      writer.save
    end
  end

  describe "#update" do

    before do
      master_collection.expects(:update)
    end

    it "delegates to the next collection" do
      writer.update
    end
  end
end
