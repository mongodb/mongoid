require "spec_helper"

describe Mongoid::Criterion::TempCollection do

  let(:collection) do
    stub.quacks_like(Mongo::Collection.allocate)
  end

  let(:database) do
    stub.quacks_like(Mongo::DB.allocate)
  end

  before do
    Mongoid.expects(:database).returns(database)
  end

  describe "#initialize" do

    before do
      Mongo::ObjectID.expects(:new).returns("coll")
      database.expects(:create_collection).with(
        "coll", :capped => true, :size => 1048576
      ).returns(collection)
      @temp = Mongoid::Criterion::TempCollection.new
    end

    it "creates a new capped collection" do
      @temp.collection.should == collection
    end

  end

end
