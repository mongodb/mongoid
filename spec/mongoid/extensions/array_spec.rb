require "spec_helper"

describe Mongoid::Extensions::Array do

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

  describe "#delete_one" do

    context "when the object doesn't exist" do

      let(:array) do
        []
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "returns nil" do
        deleted.should be_nil
      end
    end

    context "when the object exists once" do

      let(:array) do
        [ "1", "2" ]
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "deletes the object" do
        array.should eq([ "2" ])
      end

      it "returns the object" do
        deleted.should eq("1")
      end
    end

    context "when the object exists more than once" do

      let(:array) do
        [ "1", "2", "1" ]
      end

      let!(:deleted) do
        array.delete_one("1")
      end

      it "deletes the first object" do
        array.should eq([ "2", "1" ])
      end

      it "returns the object" do
        deleted.should eq("1")
      end
    end
  end
end
