require "spec_helper"

describe Mongoid::Extensions::Object::DeepCopy do

  describe "#_deep_copy" do

    context "when the object is cloneable" do

      let(:string) do
        "testing"
      end

      let(:copy) do
        string._deep_copy
      end

      it "returns an equal object" do
        copy.should eq(string)
      end

      it "returns a new instance" do
        copy.should_not equal(string)
      end
    end

    context "when the object is not cloneable" do

      let(:number) do
        1
      end

      let(:copy) do
        number._deep_copy
      end

      it "returns the same object" do
        copy.should equal(number)
      end
    end
  end
end
