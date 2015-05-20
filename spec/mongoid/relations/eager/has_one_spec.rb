require "spec_helper"

describe Mongoid::Relations::Eager::HasOne do

  describe ".grouped_doc" do

    let(:person) do
      Person.create!
    end

    let(:docs) do
      Person.all.to_a
    end

    let(:metadata) do
      Person.reflect_on_association(:cat)
    end

    let(:eager) do
      described_class.new([metadata], docs).tap do |b|
        b.shift_metadata
      end
    end

    before do
      Cat.create!(person: person)
    end

    it "aggregates by the relation primary key" do
      expect(eager.grouped_docs.keys).to eq([person.username])
    end
  end

  describe ".set_on_parent" do

    let(:person) do
      Person.create!
    end

    let(:docs) do
      Person.all.to_a
    end

    let(:metadata) do
      Person.reflect_on_association(:cat)
    end

    let(:eager) do
      described_class.new([metadata], docs).tap do |b|
        b.shift_metadata
      end
    end

    before do
      Cat.create!(person: person)
      eager
    end

    it "sets the relation into the parent" do
      docs.each do |doc|
        expect(doc).to receive(:set_relation).once.with(:cat, :foo)
      end
      eager.set_on_parent(person.username, :foo)
    end

    it "doesnt call an extra query" do
      expect_query(0) do
        eager.set_on_parent(person.username, :foo)
      end
    end
  end

  describe ".includes" do

    let(:person) do
      Person.create!
    end

    before do
      3.times { Cat.create!(person: person) }
      Cat.create!(person: Person.create!)
    end

    context "when including the has_one relation" do

      it "queries twice" do

        expect_query(2) do

          Person.all.includes(:cat).each do |person|
            expect(person.cat).to_not be_nil
          end
        end
      end
    end

    context "when including more than one has_one relation" do

      it "queries 3 times" do

        expect_query(3) do

          Person.all.includes(:cat, :account).each do |person|
            expect(person.cat).to_not be_nil
          end
        end
      end
    end

    context "when the relation is not polymorphic" do

      let!(:game) do
        person.create_game(name: "Tron")
      end

      let!(:eager) do
        Person.where(_id: person.id).includes(:game).first
      end

      it "puts the documents in the parent document" do
        expect(eager.ivar(:game)).to eq(game)
      end

      it "does not query when touching the association" do
        expect_query(0) do
          expect(eager.game).to eq(game)
        end
      end

      it "does not query when updating the association" do
        expect_query(0) do
          eager.game.name = "Revenge of Racing of Magic"
          expect(eager.game.name).to eq("Revenge of Racing of Magic")
        end
      end
    end

    context "when the relation is polymorphic" do

      let!(:book) do
        Book.create(name: "Game of Thrones")
      end

      let!(:rating) do
        book.create_rating(value: 10)
      end

      let!(:eager) do
        Book.all.includes(:rating).first
      end

      it "puts the found documents in the parent document" do
        expect(eager.ivar(:rating)).to eq(rating)
      end

      it "does not query when touching the association" do
        expect_query(0) do
          expect(eager.rating).to eq(rating)
        end
      end
    end
  end
end
