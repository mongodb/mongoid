require "spec_helper"

describe Mongoid::Collection do

  let(:master) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  let(:slave_one) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  let(:slave_two) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  let(:slaves) do
    [ slave_one, slave_two ]
  end

  let(:reader) do
    stub.quacks_like(Mongoid::Collections::Reader.allocate)
  end

  let(:writer) do
    stub.quacks_like(Mongoid::Collections::Writer.allocate)
  end

  before do
    Mongoid.expects(:master).returns(master)
    Mongoid.expects(:slaves).returns(slaves)
    @collection = Mongoid::Collection.new("mongoid_test")
  end

  describe "#[]" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:[]).with(:name)
      @collection[:name]
    end
  end

  describe "#<<" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:<<).with(:name)
      @collection << :name
    end
  end

  describe "#count" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:count)
      @collection.count
    end
  end

  describe "#create_index" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:create_index).with(:name)
      @collection.create_index(:name)
    end
  end

  describe "#distinct" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:distinct)
      @collection.distinct
    end
  end

  describe "#drop" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:drop)
      @collection.drop
    end
  end

  describe "#drop_index" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:drop_index)
      @collection.drop_index
    end
  end

  describe "#drop_indexes" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:drop_indexes)
      @collection.drop_indexes
    end
  end

  describe "#find" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:find)
      @collection.find
    end
  end

  describe "#find_one" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:find_one)
      @collection.find_one
    end
  end

  describe "#group" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:group)
      @collection.group
    end
  end

  describe "#index_information" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:index_information)
      @collection.index_information
    end
  end

  describe "#insert" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:insert)
      @collection.insert
    end
  end

  describe "#map_reduce" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:map_reduce)
      @collection.map_reduce
    end
  end

  describe "mapreduce" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:mapreduce)
      @collection.mapreduce
    end
  end

  describe "#options" do

    before do
      @collection.instance_variable_set(:@reader, reader)
    end

    it "delegates to the reader" do
      reader.expects(:options)
      @collection.options
    end
  end

  describe "#remove" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:remove)
      @collection.remove
    end
  end

  describe "#rename" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:rename)
      @collection.rename
    end
  end

  describe "#save" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:save)
      @collection.save
    end
  end

  describe "#update" do

    before do
      @collection.instance_variable_set(:@writer, writer)
    end

    it "delegates to the reader" do
      writer.expects(:update)
      @collection.update
    end
  end

end
