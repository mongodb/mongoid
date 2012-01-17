require "spec_helper"

describe Mongoid::Fields::Internal::Set do

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

  describe "#selection" do

    context "when providing a single value" do

      it "converts to a array" do
        field.selection(Set.new([ "test" ])).should eq([ "test" ])
      end
    end

    context "when providing a complex criteria" do

      let(:criteria) do
        { "$ne" => "test" }
      end

      it "returns the criteria" do
        field.selection(criteria).should eq(criteria)
      end
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
