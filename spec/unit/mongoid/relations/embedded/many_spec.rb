require "spec_helper"

describe Mongoid::Relations::Embedded::Many do

  let(:klass) do
    Mongoid::Relations::Embedded::Many
  end

  context "properties" do

    let(:documents) do
      [ stub ]
    end

    let(:metadata) do
      stub
    end

    let(:relation) do
      klass.new(documents, metadata)
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

    let(:metadata) do
      stub
    end

    let(:relation) do
      klass.new(documents, metadata)
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
