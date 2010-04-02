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

  describe "#_remove" do

    let(:remove) do
      stub.quacks_like(Mongoid::Persistence::Remove.allocate)
    end

    before do
      Mongoid::Persistence::Remove.expects(:new).with(person).returns(remove)
    end

    it "delegates to the remove persistence command" do
      remove.expects(:persist).returns(true)
      person._remove.should == true
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

  describe "#upsert" do

    context "when the document is new" do

      let(:insert) do
        stub.quacks_like(Mongoid::Persistence::Insert.allocate)
      end

      before do
        Mongoid::Persistence::Insert.expects(:new).with(person).returns(insert)
      end

      it "delegates to the insert persistence command" do
        insert.expects(:persist).returns(person)
        person.upsert
      end

      it "returns the document" do
        insert.expects(:persist).returns(person)
        person.upsert.should == person
      end
    end

    context "when the document is not new" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Update.expects(:new).with(person).returns(update)
      end

      it "delegates to the update persistence command" do
        update.expects(:persist).returns(true)
        person.upsert
      end

      it "returns a boolean" do
        update.expects(:persist).returns(true)
        person.upsert.should == true
      end
    end
  end
end
