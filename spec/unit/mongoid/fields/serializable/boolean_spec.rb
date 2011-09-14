require "spec_helper"

describe Mongoid::Fields::Serializable::Boolean do

  let(:field) do
    described_class.instantiate(:test, :type => Boolean)
  end

  describe "#deserialize" do

    it "returns the value" do
      field.deserialize(true).should be_true
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
