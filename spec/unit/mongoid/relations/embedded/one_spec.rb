require "spec_helper"

describe Mongoid::Relations::Embedded::One do

  let(:klass) do
    Mongoid::Relations::Embedded::One
  end

  let(:base) do
    Person.new
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Embedded::One
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(:extension? => false)
    end

    it "returns the embeds one builder" do
      klass.builder(metadata, document).should
        be_a_kind_of(builder_klass)
    end
  end

  describe ".embedded?" do

    it "returns true" do
      klass.should be_embedded
    end
  end

  describe ".macro" do

    it "returns :embeds_one" do
      klass.macro.should == :embeds_one
    end
  end

  context "properties" do

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(:extension? => false)
    end

    let(:relation) do
      klass.new(base, document, metadata)
    end

    before do
      document.stubs(:to_a).returns([ document ])
      document.expects(:metadata=).with(metadata)
      document.expects(:parentize).with(base)
    end

    describe "#metadata" do

      it "returns the relation's metadata" do
        relation.metadata.should == metadata
      end
    end

    describe "#target" do

      it "returns the relation's target" do
        relation.target.should == document
      end
    end
  end

  describe "#nested_build" do

    it "needs to move elsewhere"
  end

  describe "#substitute" do

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(:extension? => false)
    end

    let(:relation) do
      klass.new(base, document, metadata)
    end

    before do
      document.stubs(:to_a).returns([ document ])
      document.expects(:metadata=).with(metadata)
      document.expects(:parentize).with(base)
    end

    context "when the target is nil" do

      it "returns nil" do
        relation.substitute(nil).should be_nil
      end
    end

    context "when the target is not nil" do

      let(:new_doc) do
        stub
      end

      before do
        new_doc.stubs(:to_a).returns([ new_doc ])
        new_doc.expects(:metadata=).with(metadata)
        new_doc.expects(:parentize).with(base)
      end

      it "replaces the target" do
        relation.substitute(new_doc)
        relation.target.should == new_doc
      end

      it "returns self" do
        relation.substitute(new_doc).should == new_doc
      end
    end
  end
end
