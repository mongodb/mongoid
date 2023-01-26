# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::None do

  before do
    Band.create!(name: "Depeche Mode")
  end

  let(:context) do
    described_class.new(Band.where(name: "Depeche Mode"))
  end

  describe "#==" do

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
    it "iterates over no documents" do
      expect(context.each.entries).to be_empty
    end
  end

  describe "#exists?" do
    it "returns false" do
      expect(context).to_not be_exists
    end
  end

  describe "#distinct" do
    it "returns an empty array" do
      expect(context.distinct(:id)).to eq([])
    end
  end

  describe "#pluck" do

    context "when plucking one field" do
      it "returns an empty array" do
        expect(context.pluck(:id)).to eq([])
      end
    end

    context "when plucking multiple fields" do
      it "returns an empty array" do
        expect(context.pluck(:id, :foo)).to eq([])
      end
    end
  end

  describe "#pick" do
    it "returns an empty array" do
      expect(context.pick(:id)).to eq(nil)
    end
  end

  describe "#tally" do
    it "returns an empty hash" do
      expect(context.tally(:id)).to eq({})
    end
  end

  describe "#first" do
    it "returns nil" do
      expect(context.first).to be_nil
    end

    it "returns [] when passing a limit" do
      expect(context.first(1)).to eq([])
    end
  end

  describe "#first!" do
    it "raises an error" do
      expect do
        context.first!
      end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
    end
  end

  describe "#last" do
    it "returns nil" do
      expect(context.last).to be_nil
    end

    it "returns [] when passing a limit" do
      expect(context.last(1)).to eq([])
    end
  end

  describe "#last!" do
    it "raises an error" do
      expect do
        context.last!
      end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
    end
  end

  describe "#take" do
    it "returns nil" do
      expect(context.take).to be_nil
    end

    it "returns nil with params" do
      expect(context.take(1)).to eq([])
    end
  end

  describe "#take!" do
    it "raises an error" do
      expect do
        context.take!
      end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
    end
  end

  [ :second,
    :third,
    :fourth,
    :fifth,
    :second_to_last,
    :third_to_last
  ].each do |meth|
    describe "##{meth}" do
      it "returns nil" do
        expect(context.send(meth)).to be_nil
      end
    end

    describe "##{meth}!" do
      it "raises an error" do
        expect do
          context.send("#{meth}!")
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe "#length" do
    it "returns zero" do
      expect(context.length).to eq(0)
    end
  end

  describe "#size" do
    it "returns zero" do
      expect(context.size).to eq(0)
    end
  end
end
