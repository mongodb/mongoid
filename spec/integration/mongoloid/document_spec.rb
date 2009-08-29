require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

class Document < Mongoloid::Document
end

describe Mongoloid::Document do

  before do
    Mongoloid.database.collection("document").drop
  end

  describe "#new" do

    it "gets a new or current database connection" do
      document = Document.new
      document.collection.should be_a_kind_of(XGen::Mongo::Collection)
    end

  end

  describe "#create" do

    it "persists a new record to the database" do
      document = Document.create(:test => "Test")
      document.id.should be_a_kind_of(XGen::Mongo::ObjectID)
      document.attributes[:test].should == "Test"
    end

  end

  describe "#find" do

    before do
      Document.create(:test => "Test")
    end

    it "returns an array of documents based on the selector provided" do
      documents = Document.find(:test => "Test")
      documents[0].attributes["test"].should == "Test"
    end

    context "when selector is nil" do

      it "returns all documents" do
        documents = Document.find
        documents[0].attributes["test"].should == "Test"
      end

    end

  end

end
