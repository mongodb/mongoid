require "spec_helper"

describe Mongoid::Fields::Custom::String do

  let(:field) do
    described_class.new(:test, :type => String)
  end

  describe ".deserialize" do

    it "returns the string" do
      field.deserialize("test").should == "test"
    end
  end

  describe ".serialize" do

    context "when the value is not nil" do

      it "returns the object to_s" do
        field.serialize(1).should == "1"
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end
  end
end
