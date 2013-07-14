require "spec_helper"

describe Mongoid::Relations::Builders::Embedded::Many do

  let(:base) do
    double
  end

  let(:builder) do
    described_class.new(base, metadata, object)
  end

  describe "#build" do

    context "when passed an array of documents" do

      let(:metadata) do
        double(klass: Address, name: :addresses)
      end

      let(:object) do
        [ Address.new(city: "London") ]
      end

      let(:documents) do
        builder.build
      end

      it "returns an array of documents" do
        expect(documents).to eq(object)
      end
    end

    context "when the array is empty" do

      let(:metadata) do
        double(klass: Address, name: :addresses)
      end

      let(:object) do
        []
      end

      let(:documents) do
        builder.build
      end

      it "returns an empty array" do
        expect(documents).to eq(object)
      end
    end

    context "when passed nil" do

      let(:metadata) do
        double(klass: Address, name: :addresses)
      end

      let(:builder) do
        described_class.new(nil, metadata, nil)
      end

      let(:documents) do
        builder.build
      end

      it "returns an empty array" do
        expect(documents).to be_empty
      end
    end

    context "when no type is in the object" do

      let(:metadata) do
        double(klass: Address, name: :addresses)
      end

      let(:object) do
        [ { "city" => "London" }, { "city" => "Shanghai" } ]
      end

      let(:documents) do
        builder.build
      end

      it "returns an array of documents" do
        expect(documents).to be_a_kind_of(Array)
      end

      it "creates the correct type of documents" do
        expect(documents[0]).to be_a_kind_of(Address)
      end

      it "sets the object on the documents" do
        expect(documents[0].city).to eq("London")
        expect(documents[1].city).to eq("Shanghai")
      end
    end

    context "when a type is in the object" do

      let(:metadata) do
        double(klass: Shape, name: :shapes)
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
        expect(documents).to be_a_kind_of(Array)
      end

      it "creates the correct type of document" do
        expect(documents[0]).to be_a_kind_of(Circle)
        expect(documents[1]).to be_a_kind_of(Square)
      end

      it "sets the object on the document" do
        expect(documents[0].radius).to eq(100)
        expect(documents[1].width).to eq(50)
      end
    end
  end
end
