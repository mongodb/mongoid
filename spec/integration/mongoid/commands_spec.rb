require "spec_helper"

describe Mongoid::Commands do

  before do
    @person = Person.new(:title => "Sir")
  end

  after do
    @person.delete
  end

  describe "#delete" do

    before do
      @person.save
    end

    it "deletes the document" do
      @person.delete
      lambda { Person.find(@person.id) }.should raise_error
    end

    it "returns true" do
      @person.delete.should be_true
    end

  end

  describe "#destroy" do

    before do
      @person.save
    end

    it "deletes the document" do
      @person.destroy
      lambda { Person.find(@person.id) }.should raise_error
    end

    it "returns true" do
      @person.destroy.should be_true
    end

  end

  describe "#save" do

    context "when validation passes" do

      it "returns true" do
        @person.save.should be_true
      end

    end

  end

  describe "#update_attributes" do

    context "when validation passes" do

      it "returns true" do
        @person.update_attributes(:title => "Blah").should be_true
      end

      it "saves the attributes" do
        @person.update_attributes(:title => "Blah")
        @from_db = Person.find(@person.id)
        @from_db.title.should == "Blah"
      end

    end

  end

  describe ".create" do

    it "saves and returns the document" do
      person = Person.create(:title => "Sensei")
      person.should be_a_kind_of(Person)
      person.should_not be_a_new_record
    end

  end

  describe ".delete_all" do

    it "returns true" do
      Person.delete_all.should be_true
    end

  end

  describe ".destroy_all" do

    it "returns true" do
      Person.destroy_all.should be_true
    end

  end

end
