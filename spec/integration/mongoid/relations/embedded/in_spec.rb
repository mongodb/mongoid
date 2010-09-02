require "spec_helper"

describe Mongoid::Relations::Embedded::In do

  describe "#=" do

    context "when the child is a new record" do

      let(:person) do
        Person.new
      end

      let(:name) do
        Name.new
      end

      before do
        name.namable = person
      end

      it "sets the target of the relation" do
        name.namable.target.should == person
      end

      it "sets the base on the inverse relation" do
        person.name.should == name
      end

      it "does not save the target" do
        person.should_not be_persisted
      end
    end

    # context "when the child is not a new record" do

      # let(:person) do
        # Person.new(:ssn => "437-11-1112")
      # end

      # let(:name) do
        # Name.create
      # end

      # before do
        # name.person = person
      # end

      # it "sets the target of the relation" do
        # name.person.target.should == person
      # end

      # it "sets the foreign key of the relation" do
        # name.person_id.should == person.id
      # end

      # it "sets the base on the inverse relation" do
        # person.name.should == name
      # end

      # it "saves the target" do
        # person.should be_persisted
      # end
    # end
  # end

  describe "#= nil" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:name) do
        Name.new
      end

      before do
        name.namable = person
        name.namable = nil
      end

      it "sets the relation to nil" do
        name.namable.should be_nil
      end

      it "removed the inverse relation" do
        person.name.should be_nil
      end
    end

    # context "when the parent is not a new record" do

      # let(:person) do
        # Person.new(:ssn => "437-11-1112")
      # end

      # let(:name) do
        # Name.create
      # end

      # before do
        # name.person = person
        # name.person = nil
      # end

      # it "sets the relation to nil" do
        # name.person.should be_nil
      # end

      # it "removed the inverse relation" do
        # person.name.should be_nil
      # end

      # it "removes the foreign key value" do
        # name.person_id.should be_nil
      # end
    end
  end
end
