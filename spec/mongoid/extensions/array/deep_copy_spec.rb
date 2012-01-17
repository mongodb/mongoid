require "spec_helper"

describe Mongoid::Extensions::Array::DeepCopy do

  describe "#_deep_copy" do

    context "when the array hash clonable objects" do

      let(:one) do
        "one"
      end

      let(:two) do
        "two"
      end

      let(:array) do
        [ one, two ]
      end

      let(:copy) do
        array._deep_copy
      end

      it "clones the array" do
        copy.should eq(array)
      end

      it "returns a new instance" do
        copy.should_not equal(array)
      end

      it "deep copies the first element" do
        copy.first.should_not equal(one)
      end

      it "deep copies the last element" do
        copy.last.should_not equal(two)
      end
    end
  end
end
