require "spec_helper"

describe Mongoid::Collection do

  let(:master) do
    stub.quacks_like(Mongoid::Collections::Master.allocate)
  end

  let(:slaves) do
    stub.quacks_like(Mongoid::Collections::Slaves.allocate)
  end

  let(:collection) do
    Mongoid::Collection.new(Person, "people")
  end

  before do
    collection.instance_variable_set(:@master, master)
    collection.instance_variable_set(:@slaves, slaves)
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

  describe "master and slave" do

    context "when the database is named" do
      let(:secondary) { mock("secondary") }
      let(:secondary_slaves) { mock("secondary_slaves") }
      let(:collection) do
        Mongoid::Collection.new(Business, "businesses")
      end

      before do
        collection.instance_variable_set(:@master, nil)
        collection.instance_variable_set(:@slaves, nil)
      end

      before do
        Mongoid.expects(:databases).returns({
          "secondary" => secondary,
          "secondary_slaves" => secondary_slaves
        })
      end

      it "should use the named database master" do
        Mongoid::Collections::Master.expects(:new).with(secondary, "businesses")
        collection.master
      end

      it "should use the named database slaves" do
        Mongoid::Collections::Slaves.expects(:new).with(secondary_slaves, "businesses")
        collection.slaves
      end
    end

  end

  describe "#directed" do

    context "when an enslave option is not passed" do

      before do
        slaves.expects(:empty?).returns(false)
      end

      before do
        Person.enslave
      end

      after do
        Person.enslaved = false
      end

      it "uses the default" do
        collection.directed.should == slaves
      end
    end

    context "when an enslave option is passed" do

      before do
        slaves.expects(:empty?).returns(false)
      end

      it "overwrites the default" do
        collection.directed(:enslave => true).should == slaves
      end
    end

    context "when cached option is passed" do

      let(:options) do
        { :cache => true }
      end

      it "removed the cache option" do
        collection.directed(options).should == master
        options[:cache].should be_nil
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

    context "when an enslave option exists" do

      before do
        @options = { :enslave => true }
        slaves.expects(:empty?).returns(false)
        slaves.expects(:find).with({ :test => "value" }, {}).returns(@mongo_cursor)
      end

      it "sends the query to the slave pool" do
        collection.find({ :test => "value"}, @options).should == @cursor
      end

      it "deletes the enslave option" do
        collection.find({ :test => "value"}, @options)
        @options[:enslave].should be_nil
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

    context "when an enslave option exists" do

      before do
        @options = { :enslave => true }
        slaves.expects(:empty?).returns(false)
        slaves.expects(:find_one).with({ :test => "value" }, {}).returns(@person)
      end

      it "sends the query to the slave pool" do
        collection.find_one({ :test => "value"}, @options).should == @person
      end

      it "deletes the enslave option" do
        collection.find_one({ :test => "value"}, @options)
        @options[:enslave].should be_nil
      end
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
end
