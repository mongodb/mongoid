require "spec_helper"

describe Mongoid::Criterion::Creational do

  before do
    Person.delete_all
  end

  describe "#create" do

    context "when provided a valid selector" do

      let(:criteria) do
        Person.where(:title => "Sir")
      end

      let(:person) do
        criteria.create
      end

      it "inserts a new document into the database" do
        Person.find(person.id).should == person
      end

      it "returns the document" do
        person.should be_a(Person)
      end

      it "sets the top level attributes" do
        person.title.should == "Sir"
      end
    end

    context "when provided invalid selectors" do

      let(:criteria) do
        Person.where(:title => "Sir").and(:score.gt => 5)
      end

      let(:person) do
        criteria.create
      end

      it "ignores the attributes" do
        person.score.should be_nil
      end
    end
  end
end
