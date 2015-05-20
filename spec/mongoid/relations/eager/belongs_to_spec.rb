require "spec_helper"

describe Mongoid::Relations::Eager::BelongsTo do

  describe ".grouped_docs" do

    let(:docs) do
      Post.all.to_a
    end

    let(:person) do
      Person.create!
    end

    let(:metadata) do
      Post.reflect_on_association(:person)
    end

    let(:eager) do
      described_class.new([metadata], docs).tap do |b|
        b.shift_metadata
      end
    end

    before do
      Post.create!(person: person)
    end

    it "aggregates by the parent id" do
      expect(eager.grouped_docs.keys).to eq([person.id])
    end
  end

  describe ".set_on_parent" do

    let(:docs) do
      Post.all.to_a
    end

    let(:person) do
      Person.create!
    end

    let(:metadata) do
      Post.reflect_on_association(:person)
    end

    let(:eager) do
      described_class.new([metadata], docs).tap do |b|
        b.shift_metadata
      end
    end

    before do
      Post.create!(person: person)
    end

    it "sets the relation into the parent" do
      docs.each do |doc|
        expect(doc).to receive(:set_relation).with(:person, :foo)
      end
      eager.set_on_parent(person.id, :foo)
    end
  end

  describe ".includes" do

    let(:person) do
      Person.create!
    end

    before do
      3.times { |i| Account.create!(person: person, name: "savings#{i}") }
    end

    context "when including the belongs_to relation" do

      it "queries twice" do

        expect_query(2) do
          Account.all.includes(:person).each do |account|
            expect(account.person).to_not be_nil
          end
        end
      end
    end

    context "when the relation is not polymorphic" do

      let(:eager) do
        Post.includes(:person).last
      end

      context "when the eager load has returned documents" do

        let!(:post) do
          person.posts.create(title: "testing")
        end

        before { eager }

        it "puts the documents in the parent document" do
          expect(eager.ivar(:person)).to eq(person)
        end

        it "does not query when touching the association" do
          expect_query(0) do
            expect(eager.person).to eq(person)
          end
        end

        it "does not query when updating the association" do
          expect_query(0) do
            eager.person.username = "arthurnn"
          end
        end
      end

      context "when the eager load has not returned documents" do

        let!(:post) do
          Post.create(title: "testing")
        end

        before { eager }

        it "does not set anything on the parent" do
          expect(eager.ivar(:person)).to be nil
        end

        it "has a nil relation" do
          expect(eager.person).to be nil
        end
      end
    end

    context "when the relation is polymorphic" do

      let!(:movie) do
        Movie.create(name: "Bladerunner")
      end

      let!(:rating) do
        movie.ratings.create(value: 10)
      end

      it "raises an error" do
        expect {
          Rating.includes(:ratable).last
        }.to raise_error(Mongoid::Errors::EagerLoad)
      end
    end

    context "when setting the foreign key id directly" do

      it "works" do
        id = BSON::ObjectId.new
        game = Game.new(:person_id => id)
        expect(game.person_id).to eql(id)
      end
    end
  end
end
