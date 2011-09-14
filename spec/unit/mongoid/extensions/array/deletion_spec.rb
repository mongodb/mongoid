require "spec_helper"

describe Mongoid::Extensions::Array::Deletion do

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
