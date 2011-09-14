require "spec_helper"

describe Mongoid::Fields::Serializable::Symbol do

  let(:field) do
    described_class.instantiate(:test, :type => Symbol)
  end

  describe ".deserialize" do

    it "returns the string" do
      field.deserialize(:test).should == :test
    end
  end

  describe ".serialize" do

    context "when given nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end

    context "when string is empty" do

      it "returns nil" do
        field.serialize("").should be_nil
      end
    end

    context "when given a symbol" do

      it "returns the symbol" do
        field.serialize(:testing).should == :testing
      end
    end

    context "when given a string" do

      it "returns the symbol" do
        field.serialize("testing").should == :testing
      end
    end
  end
end
