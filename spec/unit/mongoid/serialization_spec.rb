require "spec_helper"

describe Mongoid::Serialization do

  describe ".serialize" do

    context "when provided with a type" do

      let(:value) do
        described_class.mongoize("1", Boolean)
      end

      it "serializes the value to the provided type" do
        value.should == true
      end
    end

    context "when not provided with a type" do

      let(:value) do
        described_class.mongoize(47)
      end

      it "returns the value untouched" do
        value.should == 47
      end
    end
  end
end
