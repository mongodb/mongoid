require "spec_helper"

describe Moped::BSON::Binary do

  describe "#mongoize" do

    let(:binary) do
      Moped::BSON::Binary.new(:md5, "testing")
    end

    it "returns the binary" do
      binary.mongoize.should eq(binary)
    end
  end

  describe ".demongoize" do

    let(:binary) do
      Moped::BSON::Binary.new(:md5, "testing")
    end

    let(:demongoized) do
      Moped::BSON::Binary.demongoize(binary)
    end

    it "returns the binary" do
      demongoized.should eq(binary)
    end
  end

  describe ".evolve" do

    let(:binary) do
      Moped::BSON::Binary.new(:md5, "testing")
    end

    let(:evolved) do
      Moped::BSON::Binary.evolve(binary)
    end

    it "returns the binary" do
      evolved.should eq(binary)
    end
  end

  describe ".mongoize" do

    let(:binary) do
      Moped::BSON::Binary.new(:md5, "testing")
    end

    let(:mongoized) do
      Moped::BSON::Binary.mongoize(binary)
    end

    it "returns the binary" do
      mongoized.should eq(binary)
    end
  end
end
