require "spec_helper"

describe Mongoid::Persistence::Operations::Remove do

  let(:document) do
    Patient.new(title: "Mr")
  end

  let(:address) do
    Address.new(street: "Oxford St")
  end

  let(:collection) do
    stub("collection")
  end

  let(:query) do
    stub
  end

  before do
    document.stub(:collection).and_return(collection)
  end

  describe "#initialize" do

    let(:remove) do
      described_class.new(document)
    end

    it "sets the document" do
      expect(remove.document).to eq(document)
    end

    it "sets the collection" do
      expect(remove.collection).to eq(document.collection)
    end

    it "defaults validation to true" do
      expect(remove).to be_validating
    end
  end

  describe "#persist" do

    def root_delete_expectation
      ->{
        collection.should_receive(:find).with({ "_id" => document.id }).and_return(query)
        query.should_receive(:remove).and_return(true)
      }
    end

    let(:remove) do
      described_class.new(document)
    end

    context "when the document is a root document" do

      it "removes the document from the collection" do
        root_delete_expectation.call
        expect(remove.persist).to be_true
      end
    end
  end

  describe "#persist" do

    context "when the remove succeeded" do

      let!(:person) do
        Person.create
      end

      before do
        person.delete
      end

      let(:in_map) do
        Mongoid::IdentityMap.get(Person, person.id)
      end

      it "removes the document from the identity map" do
        expect(in_map).to be_nil
      end
    end
  end

  context "when a dependent option exists" do

    context "when accessing the parent before destroy" do

      let(:artist) do
        Artist.create(name: "depeche mode")
      end

      let!(:album) do
        artist.albums.create
      end

      before do
        artist.destroy
      end

      it "allows the access" do
        expect(artist.name).to eq("destroyed")
      end

      it "destroys the associated document" do
        expect(album).to be_destroyed
      end
    end
  end
end
