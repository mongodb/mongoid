require "spec_helper"

describe Mongoid::Relations::Referenced::In do

  let(:klass) do
    Mongoid::Relations::Referenced::In
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::In
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

  describe ".foreign_key_suffix" do

    it "returns _id" do
      klass.foreign_key_suffix.should == "_id"
    end
  end

  describe ".macro" do

    it "returns referenced_in" do
      klass.macro.should == :referenced_in
    end
  end

  describe ".stores_foreign_key?" do

    it "returns true" do
      klass.stores_foreign_key?.should == true
    end
  end
end
