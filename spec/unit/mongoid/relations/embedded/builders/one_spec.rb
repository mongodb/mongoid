require "spec_helper"

describe Mongoid::Relations::Embedded::Builders::One do

  let(:klass) do
    Mongoid::Relations::Embedded::Builders::One
  end

  let(:builder) do
    klass.new(metadata, object)
  end

  describe "#build" do

    context "when provided nil" do

      let(:metadata) do
        stub(:klass => Name, :name => :name)
      end

      let(:builder) do
        klass.new(metadata, nil)
      end

      before do
        @document = builder.build
      end

      it "returns nil" do
        @document.should be_nil
      end
    end

    context "when provided a document" do

      let(:metadata) do
        stub(:klass => Name, :name => :name)
      end

      let(:object) do
        Name.new
      end

      before do
        @document = builder.build
      end

      it "returns the document" do
        @document.should == object
      end
    end

    context "when no type is in the object" do

      let(:metadata) do
        stub(:klass => Name, :name => :name)
      end

      let(:object) do
        { "first_name" => "Corbin" }
      end

      before do
        @document = builder.build
      end

      it "creates the correct type of document" do
        @document.should be_a_kind_of(Name)
      end

      it "sets the object on the document" do
        @document.first_name.should == "Corbin"
      end
    end

    context "when a type is in the object" do

      let(:metadata) do
        stub(:klass => Writer, :name => :writer)
      end

      let(:object) do
        { "_type" => "PdfWriter", "speed" => 100 }
      end

      before do
        @document = builder.build
      end

      it "creates the correct type of document" do
        @document.should be_a_kind_of(PdfWriter)
      end

      it "sets the object on the document" do
        @document.speed.should == 100
      end
    end
  end
end
