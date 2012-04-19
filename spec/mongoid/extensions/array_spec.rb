require "spec_helper"

describe Mongoid::Extensions::Array do

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

  describe ".demongoize" do

    let(:array) do
      [ 1, 2, 3 ]
    end

    it "returns the array" do
      Array.demongoize(array).should eq(array)
    end
  end

  describe ".mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:array) do
      [ date ]
    end

    let(:mongoized) do
      Array.mongoize(array)
    end

    it "mongoizes each element in the array" do
      mongoized.first.should be_a(Time)
    end

    it "converts the elements properly" do
      mongoized.first.should eq(date)
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:array) do
      [ date ]
    end

    let(:mongoized) do
      array.mongoize
    end

    it "mongoizes each element in the array" do
      mongoized.first.should be_a(Time)
    end

    it "converts the elements properly" do
      mongoized.first.should eq(date)
    end
  end
end
