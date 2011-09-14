require "spec_helper"

describe Mongoid::Persistence do

  let(:person) do
    Person.new
  end

  describe ".create" do

    let(:insert) do
      stub.quacks_like(Mongoid::Persistence::Operations::Insert.allocate)
    end

    let(:patient) do
      stub.quacks_like(Patient.allocate)
    end

    before do
      Patient.expects(:new).returns(patient)
      patient.expects(:save).returns(true)
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
      stub.quacks_like(Mongoid::Persistence::Operations::Insert.allocate)
    end

    let(:patient) do
      stub.quacks_like(Patient.allocate)
    end

    context "when validation passes" do

      before do
        Patient.expects(:new).returns(patient)
        patient.expects(:insert).returns(patient)
        patient.expects(:errors).returns([])
        patient.expects(:new?).returns(false)
      end

      it "returns the new document" do
        Patient.create!.should eq(patient)
      end
    end

    context "when validation fails" do

      let(:errors) do
        stub(:any? => true, :full_messages => [ "Message" ])
      end

      before do
        Patient.expects(:new).returns(patient)
        patient.expects(:insert).returns(patient)
        patient.expects(:errors).at_least_once.returns(errors)
      end

      it "raises an error" do
        expect { Patient.create! }.to raise_error(Mongoid::Errors::Validations)
      end
    end

    context "when a callback returns false" do

      before do
        Patient.expects(:new).returns(patient)
        patient.expects(:insert).returns(patient)
        patient.expects(:errors).at_least_once.returns([])
        patient.expects(:new?).returns(true)
      end

      it "raises an error" do
        expect { Patient.create! }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  describe ".delete_all" do

    context "when conditions provided" do

      let(:collection) do
        stub
      end

      let(:cursor) do
        stub
      end

      before do
        Person.expects(:collection).twice.returns(collection)
        collection.expects(:find).with(:field => "value").returns(cursor)
        cursor.expects(:count).returns(30)
        collection.expects(:remove).with(
          { :field => "value" },
          :safe => Mongoid.persist_in_safe_mode
        )
      end

      it "removes all documents from the collection for the conditions" do
        Person.delete_all(:conditions => { :field => "value" })
      end

      it "returns the number of documents removed" do
        Person.delete_all(:conditions => { :field => "value" }).should == 30
      end
    end

    context "when conditions not provided" do

      let(:collection) do
        stub
      end

      let(:cursor) do
        stub
      end

      before do
        Person.expects(:collection).twice.returns(collection)
        collection.expects(:find).with({}).returns(cursor)
        cursor.expects(:count).returns(30)
        collection.expects(:remove).with({}, :safe => Mongoid.persist_in_safe_mode)
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
      stub.quacks_like(Mongoid::Persistence::Operations::Remove.allocate)
    end

    context "when conditions provided" do

      before do
        Person.expects(:all).with(:conditions => { :title => "Sir" }).returns([ person ])
        person.expects(:run_callbacks).with(:destroy).yields
        Mongoid::Persistence::Operations::Remove.expects(:new).with(person, {}).returns(remove)
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
        Mongoid::Persistence::Operations::Remove.expects(:new).with(person, {}).returns(remove)
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
      stub.quacks_like(Mongoid::Persistence::Operations::Remove.allocate)
    end

    before do
      Mongoid::Persistence::Operations::Remove.expects(:new).with(person, {}).returns(remove)
    end

    it "delegates to the remove persistence command" do
      remove.expects(:persist).returns(true)
      person.delete.should == true
    end
  end

  describe "#destroy" do

    let(:remove) do
      stub.quacks_like(Mongoid::Persistence::Operations::Remove.allocate)
    end

    before do
      Mongoid::Persistence::Operations::Remove.expects(:new).with(person, {}).returns(remove)
    end

    it "delegates to the remove persistence command" do
      person.expects(:run_callbacks).with(:destroy).yields.returns(true)
      remove.expects(:persist).returns(true)
      person.destroy.should == true
    end
  end

  describe "#insert" do

    let(:insert) do
      stub.quacks_like(Mongoid::Persistence::Operations::Insert.allocate)
    end

    before do
      Mongoid::Persistence::Operations::Insert.expects(:new).with(person, {}).returns(insert)
    end

    it "delegates to the insert persistence command" do
      insert.expects(:persist).returns(person)
      person.insert.should == person
    end
  end

  describe "#remove" do

    let(:remove) do
      stub.quacks_like(Mongoid::Persistence::Operations::Remove.allocate)
    end

    before do
      Mongoid::Persistence::Operations::Remove.expects(:new).with(person, {}).returns(remove)
    end

    it "delegates to the remove persistence command" do
      remove.expects(:persist).returns(true)
      person.remove.should == true
    end
  end

  describe "#save" do

    context "when the document is new" do

      let(:insert) do
        stub.quacks_like(Mongoid::Persistence::Operations::Insert.allocate)
      end

      before do
        Mongoid::Persistence::Operations::Insert.expects(:new).with(person, {}).returns(insert)
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
        stub.quacks_like(Mongoid::Persistence::Operations::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Operations::Update.expects(:new).with(person, {}).returns(update)
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
        stub.quacks_like(Mongoid::Persistence::Operations::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Operations::Update.expects(:new).with(person, {}).returns(update)
        update.expects(:persist).returns(true)
      end

      it "returns true" do
        person.save!.should == true
      end
    end

    context "when validation failes" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Operations::Update.allocate)
      end

      let(:errors) do
        stub(:any? => true, :full_messages => [ "error" ])
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Operations::Update.expects(:new).with(person, {}).returns(update)
        update.expects(:persist).returns(false)
        person.expects(:errors).at_least_once.returns(errors)
      end

      it "raises an error" do
        lambda { person.save! }.should raise_error(Mongoid::Errors::Validations)
      end
    end

    context "when a callback fails" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Operations::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Operations::Update.expects(:new).with(person, {}).returns(update)
        update.expects(:persist).returns(false)
        person.expects(:errors).at_least_once.returns([])
      end

      it "raises an error" do
        expect { person.save! }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  describe "#update" do

    let(:update) do
      stub.quacks_like(Mongoid::Persistence::Operations::Update.allocate)
    end

    before do
      Mongoid::Persistence::Operations::Update.expects(:new).with(person, {}).returns(update)
    end

    it "delegates to the update persistence command" do
      update.expects(:persist).returns(true)
      person.update.should == true
    end
  end

  describe "#update_attributes" do

    let(:update) do
      stub.quacks_like(Mongoid::Persistence::Operations::Update.allocate)
    end

    before do
      person.instance_variable_set(:@new_record, false)
      Mongoid::Persistence::Operations::Update.expects(:new).with(person, {}).returns(update)
    end

    it "writes attributes and performs an update" do
      update.expects(:persist).returns(true)
      person.update_attributes(:title => "Mam")
      person.title.should == "Mam"
    end
  end

  describe "#update_attributes!" do

    let(:update) do
      stub.quacks_like(Mongoid::Persistence::Operations::Update.allocate)
    end

    before do
      person.instance_variable_set(:@new_record, false)
      Mongoid::Persistence::Operations::Update.expects(:new).with(person, {}).returns(update)
    end

    context "when validation passes" do

      it "writes attributes and performs an update" do
        update.expects(:persist).returns(true)
        person.update_attributes!(:title => "Mam").should be_true
        person.title.should == "Mam"
      end
    end

    context "when validation fails" do

      let(:errors) do
        stub(:any? => true, :full_messages => [ "error" ])
      end

      before do
        update.expects(:persist).returns(false)
        person.expects(:errors).at_least_once.returns(errors)
      end

      it "raises an error" do
        expect {
          person.update_attributes!(:title => "Mam")
        }.to raise_error(Mongoid::Errors::Validations)
      end
    end

    context "when a callback fails" do

      before do
        update.expects(:persist).returns(false)
        person.expects(:errors).at_least_once.returns([])
      end

      it "raises an error" do
        expect {
          person.update_attributes!(:title => "Mam")
        }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  describe "#upsert" do

    context "when passing a hash as a validation parameter" do

      let(:insert) do
        stub.quacks_like(Mongoid::Persistence::Operations::Insert.allocate)
      end

      before do
        Mongoid::Persistence::Operations::Insert.expects(:new).with(
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
        stub.quacks_like(Mongoid::Persistence::Operations::Insert.allocate)
      end

      context "when validation passes" do

        before do
          Mongoid::Persistence::Operations::Insert.expects(:new).with(person, {}).returns(insert)
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
          Mongoid::Persistence::Operations::Insert.expects(:new).with(person, {}).returns(insert)
        end

        it "returns false" do
          insert.expects(:persist).returns(person)
          person.upsert.should == false
        end
      end
    end

    context "when the document is not new" do

      let(:update) do
        stub.quacks_like(Mongoid::Persistence::Operations::Update.allocate)
      end

      before do
        person.instance_variable_set(:@new_record, false)
        Mongoid::Persistence::Operations::Update.expects(:new).with(person, {}).returns(update)
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
