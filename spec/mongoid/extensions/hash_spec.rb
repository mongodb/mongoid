require "spec_helper"

describe Mongoid::Extensions::Hash do

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
end
