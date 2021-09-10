# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Reflections do

  class TestClass
    include Mongoid::Document
  end

  let(:klass) do
    TestClass
  end

  before do
    klass.relations.clear
  end

  describe ".reflect_on_association" do

    before do
      klass.embeds_many(:addresses)
    end

    context "when the name does not exist" do

      let(:relation) do
        klass.reflect_on_association(:nonexistent)
      end

      it "returns nil" do
        expect(relation).to be_nil
      end
    end
  end

  describe ".reflect_on_all_associations" do

    context "when relations exist for the macros" do

      before do
        klass.embeds_one(:name)
        klass.embeds_many(:addresses)
        klass.has_one(:user)
      end

      context "when passing multiple arguments" do

        let(:relations) do
          klass.reflect_on_all_associations(:embeds_one, :has_one)
        end

        it "returns an array of the relations" do
          expect(relations.size).to eq(2)
        end
      end

      context "when passing a single argument" do

        let(:relations) do
          klass.reflect_on_all_associations(:embeds_one)
        end

        it "returns an array of the relations" do
          expect(relations.size).to eq(1)
        end
      end

      context "when no argument supplied" do

        let(:relations) do
          klass.reflect_on_all_associations
        end

        it "returns an array of all relations" do
          expect(relations.size).to eq(3)
        end
      end
    end

    context "when no relations exist for the macros" do

      let(:relations) do
        klass.reflect_on_all_associations(:embeds_one)
      end

      it "returns an empty array" do
        expect(relations).to be_empty
      end
    end
  end
end
