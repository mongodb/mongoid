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
      Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(true)
      @person.save
    end

    context "when document is new" do

      before do
        @person = Person.new
      end

      it "delegates to the save command" do
        Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(true)
        @person.save
      end

      it "runs the before and after create callbacks" do
        @person.expects(:run_callbacks).with(:before_create)
        Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(true)
        @person.expects(:run_callbacks).with(:after_create)
        @person.save
      end

    end

    context "when not validating" do

      before do
        @person = Person.new
      end

      it "passes the validate param to the command" do
        Mongoid::Commands::Save.expects(:execute).with(@person, false).returns(true)
        @person.save(false)
      end

    end

  end

  describe "#save!" do

    context "when validation passes" do

      it "it returns the person" do
        Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(true)
        @person.save!
      end

    end

    context "when validation fails" do

      it "it raises an error" do
        Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(false)
        lambda { @person.save! }.should raise_error
      end

    end

    context "when document is new" do

      before do
        @person = Person.new
      end

      it "delegates to the save command" do
        Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(true)
        @person.save!
      end

      context "when validation fails" do

        it "it raises an error " do
          Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(false)
          lambda { @person.save! }.should raise_error
        end

      end

      it "runs the before and after create callbacks" do
        @person.expects(:run_callbacks).with(:before_create)
        Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(true)
        @person.expects(:run_callbacks).with(:after_create)
        @person.save!
      end

    end

  end

  describe "#update_attributes" do

    it "delegates to the Save command" do
      Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(true)
      @person.update_attributes({})
    end

  end

  describe "#update_attributes!" do

    context "when validation passes" do

      it "it returns the person" do
        Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(true)
        @person.update_attributes({}).should be_true
      end

    end

    context "when validation fails" do

      it "it raises an error" do
        Mongoid::Commands::Save.expects(:execute).with(@person, true).returns(false)
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

      it "raises an error" do
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

  describe "#valid?" do

    before do
      @comment = Comment.new
    end

    it "validates the document" do
      @comment.valid?.should be_false
    end

    it "runs the validation callbacks" do
      @comment.expects(:run_callbacks).with(:validate)
      @comment.expects(:run_callbacks).with(:before_validation)
      @comment.expects(:run_callbacks).with(:after_validation)
      @comment.valid?
    end

  end

end
