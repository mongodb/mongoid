require "spec_helper"

describe BSON::Binary do

  describe "#mongoize" do

    let(:binary) do
      BSON::Binary.new("testing", :md5)
    end

    it "returns the binary" do
      expect(binary.mongoize).to eq(binary)
    end
  end

  describe ".demongoize" do

    let(:binary) do
      BSON::Binary.new("testing", :md5)
    end

    let(:demongoized) do
      BSON::Binary.demongoize(binary)
    end

    it "returns the binary" do
      expect(demongoized).to eq(binary)
    end
  end

  describe ".evolve" do

    let(:binary) do
      BSON::Binary.new("testing", :md5)
    end

    let(:evolved) do
      BSON::Binary.evolve(binary)
    end

    it "returns the binary" do
      expect(evolved).to eq(binary)
    end
  end

  describe ".mongoize" do

    let(:binary) do
      BSON::Binary.new("testing", :md5)
    end

    let(:mongoized) do
      BSON::Binary.mongoize(binary)
    end

    it "returns the binary" do
      expect(mongoized).to eq(binary)
    end
  end
end
