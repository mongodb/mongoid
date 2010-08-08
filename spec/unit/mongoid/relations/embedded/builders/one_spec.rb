require "spec_helper"

describe Mongoid::Relations::Embedded::Builders::One do

  let(:klass) do
    Mongoid::Relations::Embedded::Builders::One
  end

  let(:builder) do
    klass.new(metadata, attributes)
  end

  describe "#build" do

    context "when no type is in the attributes" do

      let(:metadata) do
        stub(:klass => Name, :name => :name)
      end

      let(:attributes) do
        {
          "title" => "Sir",
          "name" => {
            "first_name" => "Corbin"
          }
        }
      end

      before do
        @document = builder.build
      end

      it "creates the correct type of document" do
        @document.should be_a_kind_of(Name)
      end

      it "sets the attributes on the document" do
        @document.first_name.should == "Corbin"
      end
    end

    context "when a type is in the attributes" do

      let(:metadata) do
        stub(:klass => Writer, :name => :writer)
      end

      let(:attributes) do
        {
          "name" => "Canvas",
          "writer" => {
            "_type" => "PdfWriter",
            "speed" => 100
          }
        }
      end

      before do
        @document = builder.build
      end

      it "creates the correct type of document" do
        @document.should be_a_kind_of(PdfWriter)
      end

      it "sets the attributes on the document" do
        @document.speed.should == 100
      end
    end
  end
end
