require "spec_helper"

describe Mongoid::Relations::Embedded::In do

  let(:klass) do
    Mongoid::Relations::Embedded::In
  end

  context "properties" do

    let(:document) do
      stub
    end

    let(:metadata) do
      stub
    end

    let(:relation) do
      klass.new(document, metadata)
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
end
