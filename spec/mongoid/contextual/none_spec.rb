require "spec_helper"

describe Mongoid::Contextual::None do

  describe "#==" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(Band.where(name: "Depeche Mode"))
    end

    context "when the other is a none" do

      let(:other) do
        described_class.new(Band.where(name: "Depeche Mode"))
      end

      it "returns true" do
        expect(context).to eq(other)
      end
    end

    context "when the other is not a none" do

      let(:other) do
        Mongoid::Contextual::Memory.new(Band.where(name: "Depeche Mode"))
      end

      it "returns false" do
        expect(context).to_not eq(other)
      end
    end
  end

  describe "#each" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(Band.where(name: "Depeche Mode"))
    end

    it "iterates over no documents" do
      expect(context.each.entries).to be_empty
    end
  end

  describe "#exists?" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(Band.where(name: "Depeche Mode"))
    end

    it "returns false" do
      expect(context).to_not be_exists
    end
  end

  describe "#pluck" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(Band.where(name: "Depeche Mode"))
    end

    it "returns an empty array" do
      expect(context.pluck(:id)).to eq([])
    end
  end

  describe "#first" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(Band.where(name: "Depeche Mode"))
    end

    it "returns nil" do
      expect(context.first).to be_nil
    end
  end

  describe "#last" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(Band.where(name: "Depeche Mode"))
    end

    it "returns nil" do
      expect(context.last).to be_nil
    end
  end

  describe "#length" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(Band.where(name: "Depeche Mode"))
    end

    it "returns zero" do
      expect(context.length).to eq(0)
    end
  end

  describe "#size" do

    let!(:band) do
      Band.create(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(Band.where(name: "Depeche Mode"))
    end

    it "returns zero" do
      expect(context.size).to eq(0)
    end
  end
end
