require "spec_helper"

describe Mongoid::Persistence do

  let(:person) do
    Person.new
  end

  describe "#insert" do

    let(:insert) do
      stub.quacks_like(Mongoid::Persistence::Insert.allocate)
    end

    before do
      Mongoid::Persistence::Insert.expects(:new).with(person).returns(insert)
    end

    it "delegates to the insert persistence command" do
      insert.expects(:persist).returns(person)
      person.insert.should == person
    end
  end

  describe "#update" do

    let(:update) do
      stub.quacks_like(Mongoid::Persistence::Update.allocate)
    end

    before do
      Mongoid::Persistence::Update.expects(:new).with(person).returns(update)
    end

    it "delegates to the update persistence command" do
      update.expects(:persist).returns(true)
      person.update.should == true
    end
  end
end
