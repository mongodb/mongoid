require "spec_helper"

describe Mongoid::Relations::Reflections do

  class TestClass
    include Mongoid::Relations
  end

  let(:klass) do
    TestClass
  end

  before do
    klass.relations.clear
    klass.embedded = false
  end

  describe ".reflect_on_association" do

    before do
      klass.embeds_many(:addresses)
    end

    context "when the name exists" do

      let(:relation) do
        klass.reflect_on_association(:addresses)
      end

      it "returns the association metadata" do
        relation.macro.should == :embeds_many
      end
    end

    context "when the name does not exist" do

      let(:relation) do
        klass.reflect_on_association(:nonexistant)
      end

      it "returns nil" do
        relation.should be_nil
      end
    end
  end

  describe ".reflect_on_all_associations" do

    context "when relations exist for the macros" do

      before do
        klass.embeds_one(:name)
        klass.embeds_many(:addresses)
        klass.references_one(:user)
      end

      context "when passing multiple arguments" do

        let(:relations) do
          klass.reflect_on_all_associations(:embeds_one, :references_one)
        end

        it "returns an array of the relations" do
          relations.size.should == 2
        end
      end

      context "when passing a single argument" do

        let(:relations) do
          klass.reflect_on_all_associations(:embeds_one)
        end

        it "returns an array of the relations" do
          relations.size.should == 1
        end
      end
    end

    context "when no relations exist for the macros" do

      let(:relations) do
        klass.reflect_on_all_associations(:embeds_one)
      end

      it "returns an empty array" do
        relations.should == []
      end
    end

    context "when no argument supplied" do

      let(:relations) do
        klass.reflect_on_all_associations
      end

      it "returns an empty array" do
        relations.should == []
      end
    end
  end
end
