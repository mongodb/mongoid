require "spec_helper"

describe Mongoid::Fields::Internal::NilClass do

  let(:field) do
    described_class.instantiate(:test, :type => NilClass)
  end

  describe "#deserialize" do

    it "returns nil" do
      field.deserialize("testing").should be_nil
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "converts the value to nil" do
        field.selection("test").should be_nil
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

    it "returns nil" do
      field.serialize(1).should be_nil
    end
  end
end
