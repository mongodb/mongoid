require "spec_helper"

describe Mongoid::Relations::Builders::Embedded::Many do

  let(:base) do
    stub
  end

  let(:builder) do
    described_class.new(base, metadata, object)
  end

  describe "#build" do

    context "when passed an array of documents" do

      let(:metadata) do
        stub(klass: Address, name: :addresses)
      end

      let(:object) do
        [ Address.new(city: "London") ]
      end

      let(:documents) do
        builder.build
      end

      it "returns an array of documents" do
        documents.should eq(object)
      end
    end

    context "when the array is empty" do

      let(:metadata) do
        stub(klass: Address, name: :addresses)
      end

      let(:object) do
        []
      end

      let(:documents) do
        builder.build
      end

      it "returns an empty array" do
        documents.should eq(object)
      end
    end

    context "when passed nil" do

      let(:metadata) do
        stub(klass: Address, name: :addresses)
      end

      let(:builder) do
        described_class.new(nil, metadata, nil)
      end

      let(:documents) do
        builder.build
      end

      it "returns an empty array" do
        documents.should be_empty
      end
    end

    context "when no type is in the object" do

      let(:metadata) do
        stub(klass: Address, name: :addresses)
      end

      let(:object) do
        [ { "city" => "London" }, { "city" => "Shanghai" } ]
      end

      let(:documents) do
        builder.build
      end

      it "returns an array of documents" do
        documents.should be_a_kind_of(Array)
      end

      it "creates the correct type of documents" do
        documents[0].should be_a_kind_of(Address)
      end

      it "sets the object on the documents" do
        documents[0].city.should eq("London")
        documents[1].city.should eq("Shanghai")
      end
    end

    context "when a type is in the object" do

      let(:metadata) do
        stub(klass: Shape, name: :shapes)
      end

      let(:object) do
        [
          { "_type" => "Circle", "radius" => 100 },
          { "_type" => "Square", "width" => 50 }
        ]
      end

      let(:documents) do
        builder.build
      end

      it "returns an array of documents" do
        documents.should be_a_kind_of(Array)
      end

      it "creates the correct type of document" do
        documents[0].should be_a_kind_of(Circle)
        documents[1].should be_a_kind_of(Square)
      end

      it "sets the object on the document" do
        documents[0].radius.should eq(100)
        documents[1].width.should eq(50)
      end
    end
  end
end
