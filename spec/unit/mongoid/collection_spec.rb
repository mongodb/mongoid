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

    let(:collection) do
      Mongoid::Collection.new(master, slaves, "mongoid_test")
    end

    it "sets the master db"

    it "sets the slave dbs"

    it "sets the name"
  end

end
