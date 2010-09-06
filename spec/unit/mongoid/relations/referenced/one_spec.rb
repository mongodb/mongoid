require "spec_helper"

describe Mongoid::Relations::Referenced::One do

  let(:klass) do
    Mongoid::Relations::Referenced::One
  end

  let(:base) do
    Person.new
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::One
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(:extension? => false)
    end

    it "returns the embedded in builder" do
      klass.builder(metadata, document).should
        be_a_kind_of(builder_klass)
    end
  end

  describe ".embedded?" do

    it "returns false" do
      klass.should_not be_embedded
    end
  end

  describe ".foreign_key_suffix" do

    it "returns _id" do
      klass.foreign_key_suffix.should == "_id"
    end
  end

  describe ".macro" do

    it "returns references_one" do
      klass.macro.should == :references_one
    end
  end

  describe ".stores_foreign_key?" do

    it "returns false" do
      klass.stores_foreign_key?.should == false
    end
  end

  context "properties" do

    let(:document) do
      Post.new
    end

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :person,
        :inverse_setter => "person="
      )
    end

    let(:relation) do
      klass.new(base, document, metadata)
    end

    describe "#metadata" do

      it "returns the relation's metadata" do
        relation.metadata.should == metadata
      end
    end
  end
end
