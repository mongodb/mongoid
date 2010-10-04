require "spec_helper"

describe Mongoid::Relations do

  class TestClass
    include Mongoid::Relations
    include Mongoid::Dirty
    include Mongoid::Fields
  end

  let(:klass) do
    TestClass
  end

  before do
    klass.relations.clear
    klass.embedded = false
  end

  describe "#embedded?" do

    context "when the class is embedded" do

      before do
        klass.embedded_in(:person)
      end

      it "returns true" do
        klass.allocate.should be_embedded
      end
    end

    context "when the class is not embedded" do

      it "returns false" do
        klass.allocate.should_not be_embedded
      end
    end
  end

  describe ".embedded?" do

    context "when the class is embedded" do

      before do
        klass.embedded_in(:person)
      end

      it "returns true" do
        klass.should be_embedded
      end
    end

    context "when the class is not embedded" do

      it "returns false" do
        klass.should_not be_embedded
      end
    end
  end

  describe "#embedded_many?" do

    let(:person) do
      Person.new
    end

    context "when the document is in an embeds_many" do

      let(:address) do
        person.addresses.build
      end

      it "returns true" do
        address.should be_an_embedded_many
      end
    end

    context "when the document is not in an embeds_many" do

      let(:name) do
        person.build_name(:first_name => "Test")
      end

      it "returns false" do
        name.should_not be_an_embedded_many
      end
    end
  end

  describe "#embedded_one?" do

    let(:person) do
      Person.new
    end

    context "when the document is in an embeds_one" do

      let(:name) do
        person.build_name(:first_name => "Test")
      end

      it "returns true" do
        name.should be_an_embedded_one
      end
    end

    context "when the document is not in an embeds_one" do

      let(:address) do
        person.addresses.build
      end

      it "returns false" do
        address.should_not be_an_embedded_one
      end
    end
  end

  describe "#referenced_many?" do

    let(:person) do
      Person.new
    end

    context "when the document is in an references_many" do

      let(:post) do
        person.posts.build
      end

      it "returns true" do
        post.should be_a_referenced_many
      end
    end

    context "when the document is not in an references_many" do

      let(:game) do
        person.build_game(:score => 1)
      end

      it "returns false" do
        game.should_not be_a_referenced_many
      end
    end
  end

  describe "#referenced_one?" do

    let(:person) do
      Person.new
    end

    context "when the document is in an references_one" do

      let(:game) do
        person.build_game(:score => 1)
      end

      it "returns true" do
        game.should be_a_referenced_one
      end
    end

    context "when the document is not in an references_one" do

      let(:post) do
        person.posts.build
      end

      it "returns false" do
        post.should_not be_a_referenced_one
      end
    end
  end
end
