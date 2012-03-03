require "spec_helper"

describe Mongoid::Relations::Builders::Embedded::One do

  let(:base) do
    stub
  end

  let(:builder) do
    described_class.new(base, metadata, object)
  end

  describe "#build" do

    context "when provided nil" do

      let(:metadata) do
        stub(klass: Name, name: :name)
      end

      let(:builder) do
        described_class.new(nil, metadata, nil)
      end

      let(:document) do
        builder.build
      end

      it "returns nil" do
        document.should be_nil
      end
    end

    context "when provided a document" do

      let(:metadata) do
        stub(klass: Name, name: :name)
      end

      let(:object) do
        Name.new
      end

      let(:document) do
        builder.build
      end

      it "returns the document" do
        document.should eq(object)
      end
    end

    context "when no type is in the object" do

      let(:metadata) do
        stub(klass: Name, name: :name)
      end

      let(:object) do
        { "first_name" => "Corbin" }
      end

      let(:document) do
        builder.build
      end

      it "creates the correct type of document" do
        document.should be_a_kind_of(Name)
      end

      it "sets the object on the document" do
        document.first_name.should eq("Corbin")
      end
    end

    context "when a type is in the object" do

      let(:metadata) do
        stub(klass: Writer, name: :writer)
      end

      let(:object) do
        { "_type" => PdfWriter.name, "speed" => 100 }
      end

      let(:document) do
        builder.build
      end

      it "creates the correct type of document" do
        document.should be_a_kind_of(PdfWriter)
      end

      it "sets the object on the document" do
        document.speed.should eq(100)
      end
    end
  end
end
