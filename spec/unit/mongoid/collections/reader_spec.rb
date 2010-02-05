require "spec_helper"

describe Mongoid::Collections::Reader do

  let(:slave_one) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  let(:slave_one_collection) do
    stub.quacks_like(Mongo::Collection.allocate)
  end

  let(:slave_two) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  let(:slave_two_collection) do
    stub.quacks_like(Mongo::Collection.allocate)
  end

  let(:reader) do
    Mongoid::Collections::Reader.new(@slaves, "people")
  end

  before do
    slave_one.expects(:collection).with("people").returns(slave_one_collection)
    slave_two.expects(:collection).with("people").returns(slave_two_collection)
    @slaves = [ slave_one, slave_two ]
  end

  describe "#count" do

    before do
      slave_one_collection.expects(:count)
    end

    it "delegates to the next collection" do
      reader.count
    end
  end

  describe "#distinct" do

    before do
      slave_one_collection.expects(:distinct)
    end

    it "delegates to the next collection" do
      reader.distinct
    end
  end

  describe "#find" do

    before do
      slave_one_collection.expects(:find)
    end

    it "delegates to the next collection" do
      reader.find
    end
  end

  describe "#find_one" do

    before do
      slave_one_collection.expects(:find_one)
    end

    it "delegates to the next collection" do
      reader.find_one
    end
  end

  describe "#group" do

    before do
      slave_one_collection.expects(:group)
    end

    it "delegates to the next collection" do
      reader.group
    end
  end

  describe "#index_information" do

    before do
      slave_one_collection.expects(:index_information)
    end

    it "delegates to the next collection" do
      reader.index_information
    end
  end

  describe "#initialize" do

    it "sets the iterator as the cyclic iterator" do
      reader.iterator.should be_a_kind_of(Mongoid::Collections::CyclicIterator)
    end
  end

  describe "#map_reduce" do

    before do
      slave_one_collection.expects(:map_reduce)
    end

    it "delegates to the next collection" do
      reader.map_reduce
    end
  end

  describe "#mapreduce" do

    before do
      slave_one_collection.expects(:mapreduce)
    end

    it "delegates to the next collection" do
      reader.mapreduce
    end
  end

  describe "#options" do

    before do
      slave_one_collection.expects(:options)
    end

    it "delegates to the next collection" do
      reader.options
    end
  end

  describe "#size" do

    before do
      slave_one_collection.expects(:size)
    end

    it "delegates to the next collection" do
      reader.size
    end
  end
end
