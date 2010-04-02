require "spec_helper"

describe Mongoid::Persistence do

  let(:person) do
    Person.new
  end

  describe "#_delete" do

    let(:remove) do
      stub.quacks_like(Mongoid::Persistence::Remove.allocate)
    end

    before do
      Mongoid::Persistence::Remove.expects(:new).with(person).returns(remove)
    end

    it "delegates to the remove persistence command" do
      remove.expects(:persist).returns(true)
      person._delete.should == true
    end
  end

  describe "#_destroy" do

    let(:remove) do
      stub.quacks_like(Mongoid::Persistence::Remove.allocate)
    end

    before do
      Mongoid::Persistence::Remove.expects(:new).with(person).returns(remove)
    end

    it "delegates to the remove persistence command" do
      person.expects(:run_callbacks).with(:destroy).yields.returns(true)
      remove.expects(:persist).returns(true)
      person._destroy.should == true
    end
  end

  describe "#insert" do

    let(:insert) do
      stub.quacks_like(Mongoid::Persistence::Insert.allocate)
    end

    before do
      Mongoid::Persistence::Insert.expects(:new).with(person, true).returns(insert)
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

  describe "#_save" do

    context "when the document is new" do

      let(:insert) do
        stub.quacks_like(Mongoid::Persistence::Insert.allocate)
      end

      before do
        Mongoid::Persistence::Insert.expects(:new).with(person, true).returns(insert)
      end

      it "delegates to the insert persistence command" do
        insert.expects(:persist).returns(person)
        person._save
      end

      it "returns a boolean" do
        insert.expects(:persist).returns(person)
        person._save.should == true
      end
    end

    context "when the document is not new" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Update.expects(:new).with(person, true).returns(update)
      end

      it "delegates to the update persistence command" do
        update.expects(:persist).returns(true)
        person._save
      end

      it "returns a boolean" do
        update.expects(:persist).returns(true)
        person._save.should == true
      end
    end
  end

  describe "#_save!" do

    context "when validation passes" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Update.expects(:new).with(person, true).returns(update)
        update.expects(:persist).returns(true)
      end

      it "returns true" do
        person._save!.should == true
      end
    end

    context "when validation failes" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Update.expects(:new).with(person, true).returns(update)
        update.expects(:persist).returns(false)
      end

      it "raises an error" do
        lambda { person._save! }.should raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe "#update" do

    let(:update) do
      stub.quacks_like(Mongoid::Persistence::Update.allocate)
    end

    before do
      Mongoid::Persistence::Update.expects(:new).with(person, true).returns(update)
    end

    it "delegates to the update persistence command" do
      update.expects(:persist).returns(true)
      person.update.should == true
    end
  end

  describe "#upsert" do

    context "when passing a hash as a validation parameter" do

      let(:insert) do
        stub.quacks_like(Mongoid::Persistence::Insert.allocate)
      end

      before do
        Mongoid::Persistence::Insert.expects(:new).with(person, false).returns(insert)
      end

      it "delegates to the insert persistence command" do
        insert.expects(:persist).returns(person)
        person.upsert(:validate => false)
      end
    end

    context "when the document is new" do

      let(:insert) do
        stub.quacks_like(Mongoid::Persistence::Insert.allocate)
      end

      context "when validation passes" do

        before do
          Mongoid::Persistence::Insert.expects(:new).with(person, true).returns(insert)
        end

        it "delegates to the insert persistence command" do
          insert.expects(:persist).returns(person)
          person.upsert
        end

        it "returns a boolean" do
          insert.expects(:persist).returns(person)
          person.upsert.should == true
        end
      end

      context "when validation fails" do

        before do
          Mongoid::Persistence::Insert.expects(:new).with(person, true).returns(insert)
        end

        it "returns false" do
          insert.expects(:persist).returns(person)
          person.expects(:errors).returns([ "Message" ])
          person.upsert.should == false
        end
      end
    end

    context "when the document is not new" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Update.expects(:new).with(person, true).returns(update)
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
