require "spec_helper"

describe Mongoid::Relations::Builders::Embedded::Many do

  let(:klass) do
    Mongoid::Relations::Builders::Embedded::Many
  end

  let(:builder) do
    klass.new(metadata, object)
  end

  describe "#build" do

    context "when passed an array of documents" do

      let(:metadata) do
        stub(:klass => Address, :name => :addresses)
      end

      let(:object) do
        [ Address.new(:city => "London") ]
      end

      before do
        @documents = builder.build
      end

      it "returns an array of documents" do
        @documents.should == object
      end
    end

    context "when the array is empty" do

      let(:metadata) do
        stub(:klass => Address, :name => :addresses)
      end

      let(:object) do
        []
      end

      before do
        @documents = builder.build
      end

      it "returns an empty array" do
        @documents.should == object
      end
    end

    context "when passed nil" do

      let(:metadata) do
        stub(:klass => Address, :name => :addresses)
      end

      let(:builder) do
        klass.new(metadata, nil)
      end

      before do
        @documents = builder.build
      end

      it "returns an empty array" do
        @documents.should == []
      end
    end

    context "when no type is in the object" do

      let(:metadata) do
        stub(:klass => Address, :name => :addresses)
      end

      let(:object) do
        [ { "city" => "London" }, { "city" => "Shanghai" } ]
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

      it "sets the object on the documents" do
        @documents[0].city.should == "London"
        @documents[1].city.should == "Shanghai"
      end
    end

    context "when a type is in the object" do

      let(:metadata) do
        stub(:klass => Shape, :name => :shapes)
      end

      let(:object) do
        [
          { "_type" => "Circle", "radius" => 100 },
          { "_type" => "Square", "width" => 50 }
        ]
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

      it "sets the object on the document" do
        @documents[0].radius.should == 100
        @documents[1].width.should == 50
      end
    end
  end
end
