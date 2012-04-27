require "spec_helper"

describe Mongoid::Extensions::Hash do

  describe "#__evolve_object_id__" do

    let(:object_id) do
      BSON::ObjectId.new
    end

    let(:hash) do
      { field: object_id.to_s }
    end

    let(:evolved) do
      hash.__evolve_object_id__
    end

    it "converts each value in the hash" do
      evolved[:field].should eq(object_id)
    end
  end

  describe ".demongoize" do

    let(:hash) do
      { field: 1 }
    end

    it "returns the hash" do
      Hash.demongoize(hash).should eq(hash)
    end
  end

  describe ".mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:hash) do
      { date: date }
    end

    let(:mongoized) do
      Hash.mongoize(hash)
    end

    it "mongoizes each element in the hash" do
      mongoized[:date].should be_a(Time)
    end

    it "converts the elements properly" do
      mongoized[:date].should eq(date)
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:hash) do
      { date: date }
    end

    let(:mongoized) do
      hash.mongoize
    end

    it "mongoizes each element in the hash" do
      mongoized[:date].should be_a(Time)
    end

    it "converts the elements properly" do
      mongoized[:date].should eq(date)
    end
  end

  describe "#resizable?" do

    it "returns true" do
      {}.should be_resizable
    end
  end

  describe ".resizable?" do

    it "returns true" do
      Hash.should be_resizable
    end
  end
end
