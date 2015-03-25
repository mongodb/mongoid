require "spec_helper"

describe Mongoid::Contextual::TextSearch do

  before do
    Word.with(database: "admin").mongo_session.command(setParameter: 1, textSearchEnabled: true)
    Word.create_indexes
  end

  after(:all) do
    Word.remove_indexes
  end

  describe "#each" do

    let(:collection) do
      Word.collection
    end

    let(:criteria) do
      Word.all
    end

    before do
      Word.create!(name: "phase", origin: "latin")
      Word.create!(name: "phazed", origin: "latin")
    end

    context "when the search is projecting" do

      let(:search) do
        described_class.new(collection, criteria, "phase").project(name: 1)
      end

      let(:documents) do
        search.entries
      end

      it "limits the fields to the projection" do
        expect {
          documents.first.origin
        }.to raise_error(ActiveModel::MissingAttributeError)
      end
    end

    context "when the search is not projecting" do

      let(:search) do
        described_class.new(collection, criteria, "phase")
      end

      let(:documents) do
        search.entries
      end

      it "returns all fields" do
        expect(documents.first.origin).to eq("latin")
      end
    end
  end

  describe "#execute" do

    let(:collection) do
      Word.collection
    end

    let(:criteria) do
      Word.all
    end

    let(:search) do
      described_class.new(collection, criteria, "phase")
    end

    before do
      Word.create!(name: "phase", origin: "latin")
      Word.create!(name: "phazed", origin: "latin")
    end

    let(:results) do
      search.execute
    end

    it "returns the raw results" do
      expect(results).to_not be_empty
    end
  end

  describe "#initialize" do

    let(:collection) do
      Word.collection
    end

    let(:criteria) do
      Word.limit(100)
    end

    let(:search) do
      described_class.new(collection, criteria, "phase")
    end

    it "sets the collection" do
      expect(search.collection).to eq(collection)
    end

    it "sets the criteria" do
      expect(search.criteria).to eq(criteria)
    end

    it "sets the text command" do
      expect(search.command[:text]).to eq(collection.name)
    end

    it "sets the text search parameter" do
      expect(search.command[:search]).to eq("phase")
    end

    it "sets the criteria" do
      expect(search.command[:filter]).to be_empty
    end

    it "sets the limit" do
      expect(search.command[:limit]).to eq(100)
    end
  end

  describe "#language" do

    let(:collection) do
      Word.collection
    end

    let(:criteria) do
      Word.limit(100)
    end

    let(:search) do
      described_class.new(collection, criteria, "phase")
    end

    let!(:text_search) do
      search.language("deutsch")
    end

    it "sets the search language" do
      expect(search.command[:language]).to eq("deutsch")
    end

    it "returns the text search" do
      expect(text_search).to equal(search)
    end
  end

  describe "#project" do

    let(:collection) do
      Word.collection
    end

    let(:criteria) do
      Word.limit(100)
    end

    let(:search) do
      described_class.new(collection, criteria, "phase")
    end

    let!(:text_search) do
      search.project(name: 1, title: 1)
    end

    it "sets the search field limitations" do
      expect(search.command[:project]).to eq(name: 1, title: 1)
    end

    it "returns the text search" do
      expect(text_search).to equal(search)
    end
  end

  describe "#stats" do

    let(:collection) do
      Word.collection
    end

    let(:criteria) do
      Word.all
    end

    let(:search) do
      described_class.new(collection, criteria, "phase")
    end

    before do
      Word.create!(name: "phase", origin: "latin")
    end

    let(:stats) do
      search.stats
    end

    it "returns the raw stats" do
      expect(stats["nscanned"]).to eq(1)
    end
  end
end
