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

  describe "#__find_args__" do

    it "returns self" do
      expect(object.__find_args__).to eq(object)
    end
  end

  describe "#__mongoize_object_id__" do

    it "returns self" do
      expect(object.__mongoize_object_id__).to eq(object)
    end
  end

  describe "#__mongoize_time__" do

    it "returns self" do
      expect(object.__mongoize_time__).to eq(object)
    end
  end

  describe "#__sortable__" do

    it "returns self" do
      expect(object.__sortable__).to eq(object)
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

  describe "#do_or_do_not" do

    context "when the object is nil" do

      let(:result) do
        nil.do_or_do_not(:not_a_method, "The force is strong with you")
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when the object is not nil" do

      context "when the object responds to the method" do

        let(:result) do
          [ "Yoda", "Luke" ].do_or_do_not(:join, ",")
        end

        it "returns the result of the method" do
          expect(result).to eq("Yoda,Luke")
        end
      end

      context "when the object does not respond to the method" do

        let(:result) do
          "Yoda".do_or_do_not(:use, "The Force", 1000)
        end

        it "returns the result of the method" do
          expect(result).to be_nil
        end
      end
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

  describe "#you_must" do

    context "when the object is frozen" do

      let(:person) do
        Person.new.tap { |peep| peep.freeze }
      end

      let(:result) do
        person.you_must(:aliases=, [])
      end

      it "returns nil" do
        expect(result).to be_nil
      end
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

  describe "#blank_criteria?" do

    it "is false" do
      expect(object.blank_criteria?).to be false
    end
  end
end
