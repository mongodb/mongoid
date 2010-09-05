require "spec_helper"

describe Mongoid::Relations::Embedded::One do

  describe "#=" do

    context "when the child is a new record" do

      let(:person) do
        Person.new
      end

      let(:name) do
        Name.new
      end

      before do
        person.name = name
      end

      it "sets the target of the relation" do
        person.name.should == name
      end

      it "sets the base on the inverse relation" do
        name.namable.should == person
      end

      it "does not save the target" do
        name.should_not be_persisted
      end
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create(:ssn => "437-11-1112")
      end

      let(:name) do
        Name.new
      end

      before do
        person.name = name
      end

      it "sets the target of the relation" do
        person.name.should == name
      end

      it "sets the base on the inverse relation" do
        name.namable.should == person
      end

      it "saves the target" do
        name.should be_persisted
      end
    end
  end

  describe "#= nil" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:name) do
        Name.new
      end

      before do
        person.name = name
        person.name = nil
      end

      it "sets the relation to nil" do
        person.name.should be_nil
      end

      it "removes the inverse relation" do
        name.namable.should be_nil
      end
    end

    context "when the inverse is already nil" do

      let(:person) do
        Person.new
      end

      let(:name) do
        Name.new
      end

      before do
        person.name = nil
      end

      it "sets the relation to nil" do
        person.name.should be_nil
      end

      it "removes the inverse relation" do
        name.namable.should be_nil
      end
    end

    context "when the documents are not new records" do

      let(:person) do
        Person.create(:ssn => "437-11-1112")
      end

      let(:name) do
        Name.new
      end

      before do
        person.name = name
        person.name = nil
      end

      it "sets the relation to nil" do
        person.name.should be_nil
      end

      it "removed the inverse relation" do
        name.namable.should be_nil
      end

      it "deletes the child document" do
        name.should be_destroyed
      end
    end
  end
end
