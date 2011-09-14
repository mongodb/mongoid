require "spec_helper"

describe Mongoid::Fields::Serializable::NilClass do

  let(:field) do
    described_class.instantiate(:test, :type => NilClass)
  end

  describe "#deserialize" do

    it "returns nil" do
      field.deserialize("testing").should be_nil
    end
  end

  describe "#serialize" do

    it "returns nil" do
      field.serialize(1).should be_nil
    end
  end
end
