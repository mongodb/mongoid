require "spec_helper"

describe Mongoid::Collections do

  describe ".collection" do

    before do
      @person = Person.new
    end

    it "sets the collection name to the class pluralized" do
      Person.collection.name.should == "people"
    end
  end

  describe ".collection_name=" do

    context "on a parent class" do

      it "sets the collection name on the document class" do
        Patient.collection_name = "pats"
        Patient.collection_name.should == "pats"
      end
    end

    context "on a subclass" do

      after do
        Canvas.collection_name = "canvases"
      end

      it "sets the collection name for the entire hierarchy" do
        Firefox.collection_name = "browsers"
        Canvas.collection_name.should == "browsers"
      end
    end
  end

  describe ".index_information" do

    it "returns index information from the collection" do
      Person.index_information["title_1"].should_not be_nil
    end
  end

  describe ".logger=" do

    before do
      @logger = stub.quacks_like(Logger.allocate)
      Person.logger = @logger
    end

    after do
      Person.logger = nil
    end

    it "sets the logger on the connection" do
      Person.db.connection.logger.should == @logger
    end
  end

  describe ".store_in" do

    context "on a parent class" do

      it "sets the collection name and collection for the document" do
        Mongoid::Collection.expects(:new).with(Patient, "population").returns(@collection)
        Patient.store_in :population
        Patient.collection_name.should == "population"
      end
    end

    context "on a subclass" do

      after do
        Mongoid::Collection.expects(:new).with(Firefox, "canvases")
        Firefox.store_in :canvases
      end

      it "changes the collection name for the entire hierarchy" do
        Mongoid::Collection.expects(:new).with(Firefox, "browsers").returns(@collection)
        Firefox.store_in :browsers
        Canvas.collection_name.should == "browsers"
      end
    end
  end
end
