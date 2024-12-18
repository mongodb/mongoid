# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Association do

  before(:all) do
    Person.field(
      :_id,
      type: BSON::ObjectId,
      pre_processed: true,
      default: ->{ BSON::ObjectId.new },
      overwrite: true
    )
  end

  context "when class_name references an unknown class" do
    context "when loading" do
      it "does not raise an exception" do
        expect do
          class AssocationSpecModel
            include Mongoid::Document

            embedded_in :parent, class_name: 'SomethingBogusThatDoesNotExistYet'
          end
        end.not_to raise_exception
      end
    end
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
        expect(document).to be_embedded
      end
    end

    context "when the document has no parent" do

      context "when the document is embedded in" do

        it "returns true" do
          expect(document).to be_embedded
        end
      end

      context "when the document class is not embedded in" do

        it "returns false" do
          expect(person).to_not be_embedded
        end
      end
    end

    context "when the document is subclassed" do

      context "when the document has no parent" do

        it "returns false" do
          expect(Item).to_not be_embedded
        end
      end
    end

    context "when the document is a subclass" do

      context "when the document has a parent" do

        it "returns true" do
          expect(SubItem).to be_embedded
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
        expect(address).to be_an_embedded_many
      end
    end

    context "when the document is not in an embeds_many" do

      let(:name) do
        person.build_name(first_name: "Test")
      end

      it "returns false" do
        expect(name).to_not be_an_embedded_many
      end
    end

    context "when validation depends on association" do
      before(:all) do
        class Author
          include Mongoid::Document
          embeds_many :books, cascade_callbacks: true
          field :condition, type: Boolean
        end

        class Book
          include Mongoid::Document
          embedded_in :author
          validate :parent_condition_is_not_true

          def parent_condition_is_not_true
            return unless author&.condition
            errors.add :base, "Author condition is true."
          end
        end

        Author.delete_all
        Book.delete_all
      end

      let(:author) { Author.new }
      let(:book) { Book.new }

      context "when author is not persisted" do
        it "is valid without books" do
          expect(author.valid?).to be true
        end

        it "is valid with a book" do
          author.books << book
          expect(author.valid?).to be true
        end

        it "is not valid when condition is true with a book" do
          author.condition = true
          author.books << book
          expect(author.valid?).to be false
        end
      end

      context "when author is persisted" do
        before do
          author.books << book
          author.save
        end

        it "remains valid initially" do
          expect(author.valid?).to be true
        end

        it "becomes invalid when condition is set to true" do
          author.update_attributes(condition: true)
          expect(author.valid?).to be false
        end
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
        expect(name).to be_an_embedded_one
      end
    end

    context "when the document is not in an embeds_one" do

      let(:address) do
        person.addresses.build
      end

      it "returns false" do
        expect(address).to_not be_an_embedded_one
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
        expect(post).to be_a_referenced_many
      end
    end

    context "when the document is not in an references_many" do

      let(:game) do
        person.build_game(score: 1)
      end

      it "returns false" do
        expect(game).to_not be_a_referenced_many
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
        expect(game).to be_a_referenced_one
      end
    end

    context "when the document is not in an references_one" do

      let(:post) do
        person.posts.build
      end

      it "returns false" do
        expect(post).to_not be_a_referenced_one
      end
    end
  end
end
