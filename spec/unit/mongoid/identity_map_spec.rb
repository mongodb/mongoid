require "spec_helper"

describe Mongoid::IdentityMap do

  let(:identity_map) do
    described_class.new
  end

  describe "#clear" do

    before do
      identity_map.set(Person.new)
    end

    let!(:clear) do
      identity_map.clear
    end

    it "empties the identity map" do
      identity_map.should be_empty
    end

    it "returns an empty hash" do
      clear.should eq({})
    end
  end

  describe ".clear" do

    before do
      described_class.set(Person.new)
    end

    let!(:clear) do
      described_class.clear
    end

    it "returns an empty hash" do
      clear.should eq({})
    end
  end

  describe "#get" do

    let(:document) do
      Person.new
    end

    context "when the document exists in the identity map" do

      before do
        identity_map.set(document)
      end

      let(:get) do
        identity_map.get(document.id)
      end

      it "returns the matching document" do
        get.should eq(document)
      end
    end

    context "when the document does not exist in the map" do

      let(:get) do
        identity_map.get(document.id)
      end

      it "returns nil" do
        get.should be_nil
      end
    end
  end

  describe ".get" do

    let(:document) do
      Person.new
    end

    context "when the document exists in the identity map" do

      before do
        described_class.set(document)
      end

      let(:get) do
        described_class.get(document.id)
      end

      it "returns the matching document" do
        get.should eq(document)
      end
    end

    context "when the document does not exist in the map" do

      let(:get) do
        described_class.get(document.id)
      end

      it "returns nil" do
        get.should be_nil
      end
    end
  end

  describe "#get_multi" do

    let(:document_one) do
      Person.new
    end

    let(:document_two) do
      Person.new
    end

    context "when the documents exist in the identity map" do

      before do
        identity_map.set(document_one)
        identity_map.set(document_two)
      end

      context "when passed an array of ids" do

        let(:get_multi) do
          identity_map.get_multi([ document_one.id, document_two.id ])
        end

        it "returns the matching document" do
          get_multi.should eq([ document_one, document_two ])
        end
      end
    end

    context "when the documents do not exist in the map" do

      let(:get_multi) do
        identity_map.get_multi([ document_one.id, document_two.id ])
      end

      it "returns nil" do
        get_multi.should be_nil
      end
    end
  end

  describe ".get_multi" do

    let(:document_one) do
      Person.new
    end

    let(:document_two) do
      Person.new
    end

    context "when the documents exist in the identity map" do

      before do
        described_class.set(document_one)
        described_class.set(document_two)
      end

      context "when passed an array of ids" do

        let(:get_multi) do
          described_class.get_multi([ document_one.id, document_two.id ])
        end

        it "returns the matching document" do
          get_multi.should eq([ document_one, document_two ])
        end
      end
    end

    context "when the documents do not exist in the map" do

      let(:get_multi) do
        described_class.get_multi([ document_one.id, document_two.id ])
      end

      it "returns nil" do
        get_multi.should be_nil
      end
    end
  end

  describe "#set" do

    context "when setting a document" do

      let(:document) do
        Person.new
      end

      let!(:set) do
        identity_map.set(document)
      end

      it "puts the object in the identity map" do
        identity_map.get(document.id).should eq(document)
      end

      it "returns the document" do
        set.should eq(document)
      end
    end

    context "when setting nil" do

      let!(:set) do
        identity_map.set(nil)
      end

      it "places nothing in the map" do
        identity_map.should be_empty
      end

      it "returns nil" do
        set.should be_nil
      end
    end
  end

  describe ".set" do

    context "when setting a document" do

      let(:document) do
        Person.new
      end

      let!(:set) do
        described_class.set(document)
      end

      it "puts the object in the identity map" do
        described_class.get(document.id).should eq(document)
      end

      it "returns the document" do
        set.should eq(document)
      end
    end

    context "when setting nil" do

      let!(:set) do
        described_class.set(nil)
      end

      it "returns nil" do
        set.should be_nil
      end
    end
  end

  describe "#set_multi" do

    context "when setting an array of documents" do

      let(:document_one) do
        Person.new
      end

      let(:document_two) do
        Person.new
      end

      let!(:set_multi) do
        identity_map.set_multi([ document_one, document_two ])
      end

      it "puts the object in the identity map" do
        identity_map.get_multi([ document_one.id, document_two.id ]).should eq(
          [ document_one, document_two ]
        )
      end

      it "returns the documents" do
        set_multi.should eq([ document_one, document_two ])
      end
    end

    context "when setting nil" do

      let!(:set_multi) do
        identity_map.set_multi(nil)
      end

      it "places nothing in the map" do
        identity_map.should be_empty
      end

      it "returns nil" do
        set_multi.should be_nil
      end
    end

    context "when setting an empty array" do

      let!(:set_multi) do
        identity_map.set_multi([])
      end

      it "places nothing in the map" do
        identity_map.should be_empty
      end

      it "returns nil" do
        set_multi.should be_nil
      end
    end
  end

  describe ".set_multi" do

    context "when setting an array of documents" do

      let(:document_one) do
        Person.new
      end

      let(:document_two) do
        Person.new
      end

      let!(:set_multi) do
        described_class.set_multi([ document_one, document_two ])
      end

      it "puts the object in the identity map" do
        described_class.get_multi([ document_one.id, document_two.id ]).should eq(
          [ document_one, document_two ]
        )
      end

      it "returns the documents" do
        set_multi.should eq([ document_one, document_two ])
      end
    end

    context "when setting nil" do

      let!(:set_multi) do
        described_class.set_multi(nil)
      end

      it "returns nil" do
        set_multi.should be_nil
      end
    end

    context "when setting an empty array" do

      let!(:set_multi) do
        described_class.set_multi([])
      end

      it "returns nil" do
        set_multi.should be_nil
      end
    end
  end
end
