require "spec_helper"

describe Mongoid::Fields::Serializable::Set do

  let(:field) do
    described_class.instantiate(:test, :type => Set)
  end

  describe "#cast_on_read?" do

    it "returns true" do
      field.should be_cast_on_read
    end
  end

  describe "#deserialize" do

    it "returns the set if Array" do
      field.deserialize(["test"]).should == Set.new(["test"])
    end
  end

  describe "#serialize" do

    it "returns an array" do
      field.serialize(["test"]).should == ["test"]
    end

    it "returns an array even if the value is a set" do
      field.serialize(Set.new(["test"])) == ["test"]
    end
  end
end
