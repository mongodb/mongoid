require "spec_helper"

describe Mongoid::Fields::Serializable::Range do

  let(:field) do
    described_class.instantiate(:test, :type => Range)
  end

  describe "#cast_on_read?" do

    it "returns true" do
      field.should be_cast_on_read
    end
  end

  describe "#deserialize" do

    it "returns the range" do
      field.deserialize({"min" => 1, "max" => 3}).should == (1..3)
    end
  end

  describe "#serialize" do

    context "when the value is not nil" do

      it "returns the object to_hash" do
        field.serialize(1..3).should == {"min" => 1, "max" => 3}
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end
  end
end
