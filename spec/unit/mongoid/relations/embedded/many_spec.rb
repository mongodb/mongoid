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
end
