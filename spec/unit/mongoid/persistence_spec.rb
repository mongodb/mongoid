require "spec_helper"

describe Mongoid::Persistence do

  let(:person) do
    Person.new
  end

  describe ".create" do

    let(:insert) do
      stub.quacks_like(Mongoid::Persistence::Insert.allocate)
    end

    let(:patient) do
      stub.quacks_like(Patient.allocate)
    end

    before do
      Patient.expects(:new).returns(patient)
      patient.expects(:insert).returns(patient)
    end

    it "delegates to the insert persistence command" do
      Patient.create
    end

    it "returns the new document" do
      Patient.create.should == patient
    end
  end

  describe ".create!" do

    let(:insert) do
      stub.quacks_like(Mongoid::Persistence::Insert.allocate)
    end

    let(:patient) do
      stub.quacks_like(Patient.allocate)
    end

    before do
      Patient.expects(:new).returns(patient)
      patient.expects(:insert).returns(patient)
    end

    context "when validation passes" do

      before do
        patient.expects(:errors).returns([])
      end

      it "returns the new document" do
        Patient.create!.should == patient
      end
    end

    context "when validation fails" do

      before do
        errors = stub(:any? => true, :full_messages => [ "Message" ])
        patient.expects(:errors).at_least_once.returns(errors)
      end

      it "raises an error" do
        lambda { Patient.create! }.should raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe ".delete_all" do

    context "when conditions provided" do

      let(:remove_all) do
        stub.quacks_like(Mongoid::Persistence::RemoveAll.allocate)
      end

      before do
        Mongoid::Persistence::RemoveAll.expects(:new).with(
          Person,
          { :validate => false },
          { :field => "value" }
        ).returns(remove_all)
        remove_all.expects(:persist).returns(30)
      end

      it "removes all documents from the collection for the conditions" do
        Person.delete_all(:conditions => { :field => "value" })
      end

      it "returns the number of documents removed" do
        Person.delete_all(:conditions => { :field => "value" }).should == 30
      end
    end

    context "when conditions not provided" do

      let(:remove_all) do
        stub.quacks_like(Mongoid::Persistence::RemoveAll.allocate)
      end

      before do
        Mongoid::Persistence::RemoveAll.expects(:new).with(
          Person,
          { :validate => false },
          {}
        ).returns(remove_all)
        remove_all.expects(:persist).returns(30)
      end

      it "removes all documents from the collection" do
        Person.delete_all
      end

      it "returns the number of documents removed" do
        Person.delete_all.should == 30
      end
    end
  end

  describe ".destroy_all" do

    let(:remove) do
      stub.quacks_like(Mongoid::Persistence::Remove.allocate)
    end

    context "when conditions provided" do

      before do
        Person.expects(:all).with(:conditions => { :title => "Sir" }).returns([ person ])
        person.expects(:run_callbacks).with(:destroy).yields
        Mongoid::Persistence::Remove.expects(:new).with(person, {}).returns(remove)
        remove.expects(:persist).returns(true)
      end

      it "destroys each found document" do
        Person.destroy_all(:conditions => { :title => "Sir" })
      end

      it "returns the number destroyed" do
        Person.destroy_all(:conditions => { :title => "Sir" }).should == 1
      end
    end

    context "when conditions not provided" do

      before do
        Person.expects(:all).with({}).returns([ person ])
        person.expects(:run_callbacks).with(:destroy).yields
        Mongoid::Persistence::Remove.expects(:new).with(person, {}).returns(remove)
        remove.expects(:persist).returns(true)
      end

      it "destroys each found document" do
        Person.destroy_all
      end

      it "returns the number destroyed" do
        Person.destroy_all.should == 1
      end
    end
  end

  describe "#delete" do

    let(:remove) do
      stub.quacks_like(Mongoid::Persistence::Remove.allocate)
    end

    before do
      Mongoid::Persistence::Remove.expects(:new).with(person, {}).returns(remove)
    end

    it "delegates to the remove persistence command" do
      remove.expects(:persist).returns(true)
      person.delete.should == true
    end
  end

  describe "#destroy" do

    let(:remove) do
      stub.quacks_like(Mongoid::Persistence::Remove.allocate)
    end

    before do
      Mongoid::Persistence::Remove.expects(:new).with(person, {}).returns(remove)
    end

    it "delegates to the remove persistence command" do
      person.expects(:run_callbacks).with(:destroy).yields.returns(true)
      remove.expects(:persist).returns(true)
      person.destroy.should == true
    end
  end

  describe "#insert" do

    let(:insert) do
      stub.quacks_like(Mongoid::Persistence::Insert.allocate)
    end

    before do
      Mongoid::Persistence::Insert.expects(:new).with(person, {}).returns(insert)
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
      Mongoid::Persistence::Remove.expects(:new).with(person, {}).returns(remove)
    end

    it "delegates to the remove persistence command" do
      remove.expects(:persist).returns(true)
      person._remove.should == true
    end
  end

  describe "#save" do

    context "when the document is new" do

      let(:insert) do
        stub.quacks_like(Mongoid::Persistence::Insert.allocate)
      end

      before do
        Mongoid::Persistence::Insert.expects(:new).with(person, {}).returns(insert)
      end

      it "delegates to the insert persistence command" do
        insert.expects(:persist).returns(person)
        person.save
      end

      it "returns a boolean" do
        person.expects(:persisted?).returns(true)
        insert.expects(:persist).returns(person)
        person.save.should == true
      end
    end

    context "when the document is not new" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Update.expects(:new).with(person, {}).returns(update)
      end

      it "delegates to the update persistence command" do
        update.expects(:persist).returns(true)
        person.save
      end

      it "returns a boolean" do
        update.expects(:persist).returns(true)
        person.save.should == true
      end
    end
  end

  describe "#save!" do

    context "when validation passes" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Update.expects(:new).with(person, {}).returns(update)
        update.expects(:persist).returns(true)
      end

      it "returns true" do
        person.save!.should == true
      end
    end

    context "when validation failes" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Update.expects(:new).with(person, {}).returns(update)
        update.expects(:persist).returns(false)
      end

      it "raises an error" do
        lambda { person.save! }.should raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe "#update" do

    let(:update) do
      stub.quacks_like(Mongoid::Persistence::Update.allocate)
    end

    before do
      Mongoid::Persistence::Update.expects(:new).with(person, {}).returns(update)
    end

    it "delegates to the update persistence command" do
      update.expects(:persist).returns(true)
      person.update.should == true
    end
  end

  describe "#update_attributes" do

    let(:update) do
      stub.quacks_like(Mongoid::Persistence::Update.allocate)
    end

    before do
      person.instance_variable_set(:@new_record, false)
      Mongoid::Persistence::Update.expects(:new).with(person, {}).returns(update)
    end

    it "writes attributes and performs an update" do
      update.expects(:persist).returns(true)
      person.update_attributes(:title => "Mam")
      person.title.should == "Mam"
    end
  end

  describe "#update_attributes!" do

    let(:update) do
      stub.quacks_like(Mongoid::Persistence::Update.allocate)
    end

    before do
      person.instance_variable_set(:@new_record, false)
      Mongoid::Persistence::Update.expects(:new).with(person, {}).returns(update)
    end

    context "when validation passes" do

      it "writes attributes and performs an update" do
        update.expects(:persist).returns(true)
        person.update_attributes!(:title => "Mam").should be_true
        person.title.should == "Mam"
      end
    end

    context "when validation fails" do

      it "raises an error" do
        update.expects(:persist).returns(false)
        lambda {
          person.update_attributes!(:title => "Mam")
        }.should raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe "#upsert" do

    context "when passing a hash as a validation parameter" do

      let(:insert) do
        stub.quacks_like(Mongoid::Persistence::Insert.allocate)
      end

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :validate => false }
        ).returns(insert)
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
          Mongoid::Persistence::Insert.expects(:new).with(person, {}).returns(insert)
        end

        it "delegates to the insert persistence command" do
          person.expects(:persisted?).returns(true)
          insert.expects(:persist).returns(person)
          person.upsert
        end

        it "returns a boolean" do
          person.expects(:persisted?).returns(true)
          insert.expects(:persist).returns(person)
          person.upsert.should == true
        end
      end

      context "when validation fails" do

        before do
          Mongoid::Persistence::Insert.expects(:new).with(person, {}).returns(insert)
        end

        it "returns false" do
          insert.expects(:persist).returns(person)
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
        Mongoid::Persistence::Update.expects(:new).with(person, {}).returns(update)
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
