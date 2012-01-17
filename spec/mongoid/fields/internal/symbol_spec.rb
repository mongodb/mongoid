require "spec_helper"

describe Mongoid::Fields::Internal::Symbol do

  let(:field) do
    described_class.instantiate(:test, :type => Symbol)
  end

  describe "#deserialize" do

    context "when provided a symbol" do

      it "returns the symbol" do
        field.deserialize(:test).should == :test
      end
    end

    context "when provided a string" do

      it "returns a symbol" do
        field.deserialize("test").should eq(:test)
      end
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "converts the value to a symbol" do
        field.selection("test").should eq(:test)
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
