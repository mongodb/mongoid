require "spec_helper"

describe Mongoid::Collections do

  describe ".collection" do

    let(:person) do
      Person.new
    end

    it "sets the collection name to the class pluralized" do
      Person.collection.name.should eq("people")
    end

    context "when the document is embedded" do

      context "when there is no cyclic relation" do

        it "raises an error" do
          expect { Address.collection }.to raise_error
        end
      end

      context "when a cyclic relation exists" do

        it "returns the collection" do
          Role.collection.should be_a(Mongoid::Collection)
        end
      end
    end
  end

  describe ".collection_name=" do

    context "on a parent class" do

      it "sets the collection name on the document class" do
        Patient.collection_name = "pats"
        Patient.collection_name.should eq("pats")
      end
    end

    context "on a subclass" do

      after do
        Canvas.collection_name = "canvases"
      end

      it "sets the collection name for the entire hierarchy" do
        Firefox.collection_name = "browsers"
        Canvas.collection_name.should eq("browsers")
      end
    end
  end

  describe ".index_information" do

    before do
      Mongoid.autocreate_indexes = true
    end

    after do
      Mongoid.autocreate_indexes = false
    end

    it "returns index information from the collection" do
      Person.index_information["title_1"].should_not be_nil
    end
  end

  describe ".store_in" do

    context "when providing options" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
        end
      end

      before do
        klass.store_in :caps, :capped => true, :size => 1000
      end

      after do
        klass.collection.drop
      end

      let(:options) do
        klass.collection.options
      end

      it "passes the capped options to the collection" do
        options["capped"].should be_true
      end

      it "passes the size options to the collection" do
        options["size"].should eq(1000)
      end
    end

    context "when setting on a parent class" do

      before do
        Patient.store_in :population
      end

      it "sets the collection name" do
        Patient.collection_name.should eq("population")
      end
    end

    context "when setting on a subclass" do

      before do
        Firefox.store_in :browsers
      end

      after do
        Firefox.store_in :canvases
      end

      it "changes the collection name for the entire hierarchy" do
        Canvas.collection_name.should eq("browsers")
      end
    end
  end
end
