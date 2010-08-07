require "spec_helper"

describe Mongoid::Relations::Embedded::Many do

  let(:klass) do
    Mongoid::Relations::Embedded::Many
  end

  let(:metadata) do
    stub(:name => :addresses, :klass => Address)
  end

  let(:base) do
    Person.new
  end

  describe "#<<" do

    context "when adding a single document" do

      let(:address) do
        Address.new
      end

      let(:document) do
        address
      end

      let(:relation) do
        klass.new(base, [], metadata)
      end

      before do
        relation << document
      end

      it "adds the parent to the document" do
        address._parent.should == base
      end

      it "appends to the target" do
        relation.target.size.should == 1
      end

      it "sets the index" do
        address._index.should == 0
      end
    end

    context "when adding multiple documents" do

      let(:address) do
        Address.new
      end

      let(:documents) do
        [ address ]
      end

      let(:relation) do
        klass.new(base, [], metadata)
      end

      before do
        relation << documents
      end

      it "adds the parent to the documents" do
        address._parent.should == base
      end

      it "appends to the target" do
        relation.target.size.should == 1
      end

      it "sets the indices" do
        address._index.should == 0
      end
    end
  end

  describe "#build" do

    context "when providing a type" do

      let(:base) do
        Canvas.new
      end

      let(:metadata) do
        stub(:name => :shapes, :klass => Shape)
      end

      let(:relation) do
        klass.new(base, [], metadata)
      end

      before do
        @shape = relation.build(
          { :radius => 10 },
          Circle
        )
      end

      it "returns a new document" do
        @shape.should be_a_kind_of(Circle)
      end

      it "sets the attributes on the new document" do
        @shape.radius.should == 10
      end

      it "sets the type on the new document" do
        @shape._type.should == "Circle"
      end

      it "adds the parent to the new document" do
        @shape._parent.should == base
      end

      it "appends to the target" do
        relation.target.size.should == 1
      end

      it "sets the indices" do
        @shape._index.should == 0
      end
    end

    context "when not providing a type" do

      let(:relation) do
        klass.new(base, [], metadata)
      end

      before do
        @address = relation.build(:street => "Nan Jing Dong Lu")
      end

      it "returns a new document" do
        @address.should be_a_kind_of(Address)
      end

      it "sets the attributes on the new document" do
        @address.street.should == "Nan Jing Dong Lu"
      end

      it "adds the parent to the new document" do
        @address._parent.should == base
      end

      it "appends to the target" do
        relation.target.size.should == 1
      end

      it "sets the indices" do
        @address._index.should == 0
      end
    end
  end

  context "properties" do

    let(:documents) do
      [ stub ]
    end

    let(:relation) do
      klass.new(base, documents, metadata)
    end

    describe "#metadata" do

      it "returns the relation's metadata" do
        relation.metadata.should == metadata
      end
    end

    describe "#target" do

      it "returns the relation's target" do
        relation.target.should == documents
      end
    end
  end

  describe "#substitute" do

    let(:documents) do
      [ stub ]
    end

    let(:relation) do
      klass.new(base, documents, metadata)
    end

    context "when the target is nil" do

      it "clears out the target" do
        relation.substitute(nil)
        relation.target.should == []
      end

      it "returns self" do
        relation.substitute(nil).should == relation
      end
    end

    context "when the target is not nil" do

      let(:new_docs) do
        [ stub ]
      end

      it "replaces the target" do
        relation.substitute(new_docs)
        relation.target.should == new_docs
      end

      it "returns self" do
        relation.substitute(new_docs).should == relation
      end
    end
  end
end
