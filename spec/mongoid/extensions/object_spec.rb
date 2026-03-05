# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Extensions::Object do

  let(:object) do
    Object.new
  end

  describe "#__evolve_object_id__" do

    it "returns self" do
      expect(object.__evolve_object_id__).to eq(object)
    end
  end

  describe "#__mongoize_object_id__" do

    it "returns self" do
      expect(object.__mongoize_object_id__).to eq(object)
    end
  end

  describe ".demongoize" do

    let(:object) do
      "testing"
    end

    it "returns the provided object" do
      expect(Object.demongoize(object)).to eq(object)
    end
  end

  describe ".mongoize" do

    let(:object) do
      "testing"
    end

    it "returns the provided object" do
      expect(Object.mongoize(object)).to eq(object)
    end
  end

  describe "#mongoize" do

    let(:object) do
      "testing"
    end

    it "returns the object" do
      expect(object.mongoize).to eq(object)
    end
  end

  describe "#resizable?" do

    it "returns false" do
      expect(Object.new).to_not be_resizable
    end
  end

  describe "#remove_ivar" do

    context "when the instance variable is defined" do

      let(:document) do
        Person.new
      end

      before do
        document.instance_variable_set(:@_testing, "testing")
      end

      let!(:removal) do
        document.remove_ivar("testing")
      end

      it "removes the instance variable" do
        expect(document.instance_variable_defined?(:@_testing)).to be false
      end

      it "returns the value" do
        expect(removal).to eq("testing")
      end
    end

    context "when the instance variable is not defined" do

      let(:document) do
        Person.new
      end

      let!(:removal) do
        document.remove_ivar("testing")
      end

      it "returns false" do
        expect(removal).to be false
      end
    end
  end

  describe "#numeric?" do

    it "returns false" do
      expect(object.numeric?).to eq(false)
    end
  end
end
