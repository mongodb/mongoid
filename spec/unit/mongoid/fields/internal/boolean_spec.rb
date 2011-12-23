require "spec_helper"

describe Mongoid::Fields::Internal::Boolean do

  let(:field) do
    described_class.instantiate(:test, :type => Boolean)
  end

  describe "#deserialize" do

    it "returns the value" do
      field.deserialize(true).should be_true
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "converts the value to a boolean" do
        field.selection("true").should eq(true)
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

    context "when provided true" do

      it "returns true" do
        field.serialize("true").should be_true
      end
    end

    context "when provided false" do

      it "returns false" do
        field.serialize("false").should be_false
      end
    end

    context "when provided 0" do

      it "returns false" do
        field.serialize("0").should be_false
      end
    end

    context "when provided 1" do

      it "returns true" do
        field.serialize("1").should be_true
      end
    end

    context "when provided nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end
  end
end
