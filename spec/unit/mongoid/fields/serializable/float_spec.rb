require "spec_helper"

describe Mongoid::Fields::Serializable::Float do

  let(:field) do
    described_class.instantiate(:test, :type => Float)
  end

  describe "#deserialize" do

    it "returns the float" do
      field.deserialize(3.45).should == 3.45
    end
  end

  describe "#serialize" do

    context "when the value is a number" do

      it "converts the number to a float" do
        field.serialize(3.45).should == 3.45
      end
    end

    context "when the value is not a number" do

      context "when the value is non numerical" do

        it "returns the string" do
          field.serialize("foo").should == "foo"
        end
      end

      context "when the string is numerical" do

        it "returns the float value for the string" do
          field.serialize("3.45").should == 3.45
        end
      end

      context "when the string is empty" do

        it "returns 0.0" do
          field.serialize("").should be_nil
        end
      end

      context "when the string is nil" do

        it "returns 0.0" do
          field.serialize(nil).should be_nil
        end
      end
    end
  end
end
