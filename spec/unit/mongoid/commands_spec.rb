require "spec_helper"

describe Mongoid::Commands do

  before do
    @person = Person.new(:_id => Mongo::ObjectID.new.to_s)
  end

  describe "#delete" do

    it "delegates to the Delete command" do
      Mongoid::Commands::Delete.expects(:execute).with(@person)
      @person.delete
    end

  end

  describe "#destroy" do

    it "delegates to the Destroy command" do
      Mongoid::Commands::Destroy.expects(:execute).with(@person)
      @person.destroy
    end

  end

  describe "#save" do

    it "delegates to the Save command" do
      Mongoid::Commands::Save.expects(:execute).with(@person).returns(true)
      @person.save
    end

    context "when document is new" do

      before do
        @person = Person.new
      end

      it "delegates to the Create command" do
        Mongoid::Commands::Create.expects(:execute).with(@person).returns(@person)
        @person.save
      end

    end

  end

  describe "#save!" do

    context "when validation passes" do

      it "it returns the person" do
        Mongoid::Commands::Save.expects(:execute).with(@person).returns(@person)
        @person.save!.should == @person
      end

    end

    context "when validation fails" do

      it "it raises a ValidationsError" do
        Mongoid::Commands::Save.expects(:execute).with(@person).returns(false)
        lambda { @person.save! }.should raise_error
      end

    end

    context "when document is new" do

      before do
        @person = Person.new
      end

      it "delegates to the Create command" do
        Mongoid::Commands::Create.expects(:execute).with(@person).returns(@person)
        @person.save!
      end

      context "when validation fails" do

        it "it raises a ValidationsError" do
          Mongoid::Commands::Create.expects(:execute).with(@person).returns(false)
          lambda { @person.save! }.should raise_error
        end

      end

    end

  end

  describe "#update_attributes" do

    it "delegates to the Save command" do
      Mongoid::Commands::Save.expects(:execute).with(@person).returns(@person)
      @person.update_attributes({})
    end

  end

  describe "#update_attributes!" do

    context "when validation passes" do

      it "it returns the person" do
        Mongoid::Commands::Save.expects(:execute).with(@person).returns(@person)
        @person.update_attributes({}).should == @person
      end

    end

    context "when validation fails" do

      it "it raises a ValidationsError" do
        Mongoid::Commands::Save.expects(:execute).with(@person).returns(false)
        lambda { @person.update_attributes!({}) }.should raise_error
      end

    end

  end

  describe ".create" do

    it "delegates to the Create command" do
      Mongoid::Commands::Create.expects(:execute)
      Person.create
    end

    it "returns the document" do
      Mongoid::Commands::Create.expects(:execute).returns(Person.new)
      Person.create.should_not be_nil
    end

  end

  describe ".create!" do

    it "delegates to the Create command" do
      Mongoid::Commands::Create.expects(:execute).returns(Person.new)
      Person.create!
    end

    it "returns the document" do
      Mongoid::Commands::Create.expects(:execute).returns(Person.new)
      Person.create!.should_not be_nil
    end

    context "when validation fails" do

      it "raises an exception" do
        person = stub(:errors => stub(:empty? => false))
        Mongoid::Commands::Create.expects(:execute).returns(person)
        lambda { Person.create! }.should raise_error
      end

    end

  end

  describe ".delete_all" do

    it "delegates to the DeleteAll command" do
      Mongoid::Commands::DeleteAll.expects(:execute).with(Person, {})
      Person.delete_all
    end

  end

  describe ".destroy_all" do

    it "delegates to the DestroyAll command" do
      Mongoid::Commands::DestroyAll.expects(:execute).with(Person, {})
      Person.destroy_all
    end

  end

end
