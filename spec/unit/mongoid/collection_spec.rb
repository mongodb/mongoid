require "spec_helper"

describe Mongoid::Collection do

  let(:master) do
    stub.quacks_like(Mongoid::Collections::Master.allocate)
  end

  let(:collection) do
    Mongoid::Collection.new(Person, "people")
  end

  before do
    collection.instance_variable_set(:@master, master)
  end

  context "Mongo::Collection write operations" do

    Mongoid::Collections::Operations::WRITE.each do |name|

      it "defines #{name}" do
        collection.should respond_to(name)
      end
    end

  end

  context "Mongo::Collection read operations" do

    Mongoid::Collections::Operations::READ.each do |name|

      it "defines #{name}" do
        collection.should respond_to(name)
      end
    end
  end

  context "when secondary databases exist" do

    context "when the database is named" do

      let(:secondary) do
        mock("secondary")
      end

      let(:collection) do
        Mongoid::Collection.new(Business, "businesses")
      end

      before do
        collection.instance_variable_set(:@master, nil)
      end

      before do
        Mongoid.expects(:databases).returns({
          "secondary" => secondary
        })
      end

      it "should use the named database master" do
        Mongoid::Collections::Master.expects(:new).with(secondary, "businesses", {})
        collection.master
      end
    end
  end

  describe "#find" do

    before do
      @cursor = stub.quacks_like(Mongoid::Cursor.allocate)
      Mongoid::Cursor.expects(:new).with(Person, collection, @mongo_cursor).returns(@cursor)
    end

    context "when no block supplied" do

      before do
        master.expects(:find).with({ :test => "value" }, {}).returns(@mongo_cursor)
      end

      it "finds return a cursor" do
        collection.find({ :test => "value"}).should == @cursor
      end

    end

    context "when a block is supplied" do

      before do
        master.expects(:find).with({ :test => "value" }, {}).returns(@mongo_cursor)
      end

      it "yields to the cursor and closes it" do
        @cursor.expects(:close).returns(true)
        collection.find({ :test => "value" }) do |cur|
          cur.should == @cursor
        end
      end
    end

    context "when an enslave option does not exist" do

      before do
        master.expects(:find).with({ :test => "value" }, {}).returns(@mongo_cursor)
      end

      it "sends the query to the master" do
        collection.find({ :test => "value"}).should == @cursor
      end
    end
  end

  describe "#find_one" do

    before do
      @person = stub
    end

    context "when an enslave option does not exist" do

      before do
        master.expects(:find_one).with({ :test => "value" }, {}).returns(@person)
      end

      it "sends the query to the master" do
        collection.find_one({ :test => "value"}).should == @person
      end
    end
  end

  describe "#insert" do

    let(:document) do
      { "$set" => { "field" => "value" } }
    end

    context "when no inserter exists on the current thread" do

      it "delegates straight to the master collection" do
        master.expects(:insert).with(document, {})
        collection.insert(document)
      end
    end
  end

  describe "#update" do

    let(:selector) do
      { "_id" => BSON::ObjectId.new }
    end

    let(:document) do
      { "$set" => { "field" => "value" } }
    end

    context "when no updater exists on the current thread" do

      it "delegates straight to the master collection" do
        master.expects(:update).with(selector, document, {})
        collection.update(selector, document)
      end
    end
  end
end
