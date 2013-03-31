require "spec_helper"

describe Moped::BSON::Binary do

  describe "#mongoize" do

    let(:binary) do
      Moped::BSON::Binary.new(:md5, "testing")
    end

    it "returns the binary" do
      expect(binary.mongoize).to eq(binary)
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
      expect(demongoized).to eq(binary)
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
      expect(evolved).to eq(binary)
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
      expect(mongoized).to eq(binary)
    end
  end
end
