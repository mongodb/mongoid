require "spec_helper"

describe Mongoid::Relations::Embedded::Builders::Many do

  let(:klass) do
    Mongoid::Relations::Embedded::Builders::Many
  end

  let(:builder) do
    klass.new(metadata, attributes)
  end

  describe "#build" do

    context "when no type is in the attributes" do

      let(:metadata) do
        stub(:klass => Address, :name => :addresses)
      end

      let(:attributes) do
        {
          "title" => "Sir",
          "addresses" => [
            { "city" => "London" }, { "city" => "Shanghai" }
          ]
        }
      end

      before do
        @documents = builder.build
      end

      it "returns an array of documents" do
        @documents.should be_a_kind_of(Array)
      end

      it "creates the correct type of documents" do
        @documents[0].should be_a_kind_of(Address)
      end

      it "sets the attributes on the documents" do
        @documents[0].city.should == "London"
        @documents[1].city.should == "Shanghai"
      end
    end

    context "when a type is in the attributes" do

      let(:metadata) do
        stub(:klass => Shape, :name => :shapes)
      end

      let(:attributes) do
        {
          "name" => "Canvas",
          "shapes" => [
            { "_type" => "Circle", "radius" => 100 },
            { "_type" => "Square", "width" => 50 }
          ]
        }
      end

      before do
        @documents = builder.build
      end

      it "returns an array of documents" do
        @documents.should be_a_kind_of(Array)
      end

      it "creates the correct type of document" do
        @documents[0].should be_a_kind_of(Circle)
        @documents[1].should be_a_kind_of(Square)
      end

      it "sets the attributes on the document" do
        @documents[0].radius.should == 100
        @documents[1].width.should == 50
      end
    end
  end
end
