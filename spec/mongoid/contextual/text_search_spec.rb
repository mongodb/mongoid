require "spec_helper"

describe Mongoid::Contextual::TextSearch do

  describe "#execute" do

    before do
      Word.with(database: "admin").mongo_session.command(setParameter: 1, textSearchEnabled: true)
      Word.create_indexes
    end

    after(:all) do
      Word.remove_indexes
    end

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
      Word.with(safe: true).create!(name: "phase", origin: "latin")
      Word.with(safe: true).create!(name: "phazed", origin: "latin")
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
end
