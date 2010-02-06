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

  describe "#initialize" do

    before do
      Mongoid.expects(:master).returns(master)
    end

    context "when slaves exist" do

      before do
        Mongoid.expects(:slaves).returns(slaves)
        Mongoid::Collections::Writer.expects(:new).with(master, "mongoid_test")
      end

      it "sets the reader with slaves" do
        Mongoid::Collections::Reader.expects(:new).with(slaves, "mongoid_test")
        Mongoid::Collection.new("mongoid_test")
      end

    end

    context "when slaves do not exist" do

      before do
        Mongoid.expects(:slaves).returns(nil)
        Mongoid::Collections::Writer.expects(:new).with(master, "mongoid_test")
      end

      it "sets the reader to an array with the master" do
        Mongoid::Collections::Reader.expects(:new).with([ master ], "mongoid_test")
        Mongoid::Collection.new("mongoid_test")
      end
    end

  end

end
