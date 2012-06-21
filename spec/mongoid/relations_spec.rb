require "spec_helper"

describe Mongoid::Relations do

  before(:all) do
    Person.field(
      :_id,
      type: Moped::BSON::ObjectId,
      pre_processed: true,
      default: ->{ Moped::BSON::ObjectId.new }
    )
  end

  describe "#embedded?" do

    let(:person) do
      Person.new
    end

    let(:document) do
      Email.new
    end

    context "when the document has a parent" do

      before do
        document.parentize(person)
      end

      it "returns true" do
        document.should be_embedded
      end
    end

    context "when the document has no parent" do

      context "when the document is embedded in" do

        it "returns true" do
          document.should be_embedded
        end
      end

      context "when the document class is not embedded in" do

        it "returns false" do
          person.should_not be_embedded
        end
      end
    end

    context "when the document is subclassed" do

      context "when the document has no parent" do

        it "returns false" do
          Item.should_not be_embedded
        end
      end
    end

    context "when the document is a subclass" do

      context "when the document has a parent" do

        it "returns true" do
          SubItem.should be_embedded
        end
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
        person.build_name(first_name: "Test")
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
        person.build_name(first_name: "Test")
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
        person.build_game(score: 1)
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
        person.build_game(score: 1)
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
