require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoloid::Document do

  before do
    Mongoloid.database.collection(:people).drop
  end

  describe "#new" do

    it "gets a new or current database connection" do
      person = Person.new
      person.collection.should be_a_kind_of(XGen::Mongo::Collection)
    end

  end

  describe "#create" do

    it "persists a new record to the database" do
      person = Person.create(:test => "Test")
      person.id.should be_a_kind_of(XGen::Mongo::ObjectID)
      person.attributes[:test].should == "Test"
    end

  end

  describe "#find" do

    before do
      Person.create(:test => "Test", :document_class => "Person")
    end

    context "finding all documents" do

      it "returns an array of documents based on the selector provided" do
        documents = Person.find(:all, :test => "Test")
        documents[0].attributes["test"].should == "Test"
      end

    end

    context "finding first document" do

      it "returns the first document based on the selector provided" do
        person = Person.find(:first, :test => "Test")
        person.attributes["test"].should == "Test"
      end

    end

  end

  describe "#paginate" do

    before do
      30.times do |num|
        Person.create(:test => "Test-#{num}", :document_class => "Person")
      end
    end

    it "returns paginated documents" do
      Person.paginate({}, { :per_page => 20, :page => 2 }).length.should == 10
    end

  end

end
