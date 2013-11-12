require "spec_helper"

describe Mongoid::Relations::Eager::HasMany do

  describe ".grouped_docs" do

    let(:docs) do
      Person.all.to_a
    end

    let(:person) do
      Person.create!
    end

    let(:metadata) do
      Person.reflect_on_association(:posts)
    end

    let(:eager) do
      described_class.new([metadata], docs).tap do |b|
        b.shift_metadata
      end
    end

    before do
      Post.create!(person: person)
    end

    it "aggregates by the parent primary key" do
      expect(eager.grouped_docs.keys).to eq([person.id])
    end
  end

  describe ".set_on_parent" do

    let(:docs) do
      Person.all.to_a
    end

    let(:person) do
      Person.create!
    end

    let(:metadata) do
      Person.reflect_on_association(:posts)
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
        expect(doc).to receive(:set_relation).with(:posts, :foo)
      end
      eager.set_on_parent(person.id, :foo)
    end
  end

  describe ".includes" do

    let(:person) do
      Person.create!
    end

    context "when including the has_many relation" do

      before do
        3.times { Drug.create!(person: person) }
        Drug.create!(person: Person.create!)
      end

      it "queries twice" do

        expect_query(2) do
          Person.all.includes(:drugs).each do |person|
            expect(person.drugs).to_not be_nil
          end
        end
      end
    end

    context "when the relation is not polymorphic" do

      context "when the eager load has returned documents" do

        let!(:post) do
          person.posts.create(title: "testing")
        end

        let!(:eager) do
          Person.includes(:posts).last
        end

        it "puts the documents in the parent document" do
          expect(eager.ivar(:posts)).to eq([post])
        end

        it "does not query when touching the association" do
          expect_query(0) do
            expect(eager.posts).to eq([post])
          end
        end

        it "does not query when updating the association" do
          expect_query(0) do
            eager.posts.first.title = "New title"
          end
        end
      end

      context "when the eager load has not returned documents" do

        before do
          person
        end

        let!(:eager) do
          Person.includes(:posts).last
        end

        it "does not set anything on the parent" do
          expect(eager.ivar(:posts)).to be_falsey
        end

        it "tries to query again when touching the association" do
          expect_query(1) do
            expect(eager.posts).to be_empty
          end
        end
      end

      context "when the eager load has not returned documents for some" do

        let!(:person_one) do
          person
        end

        let!(:person_two) do
          Person.create(username: "durran")
        end

        let!(:post) do
          person_one.posts.create(title: "testing")
        end

        let!(:eager) do
          Person.includes(:posts).asc(:username).to_a
        end

        it "puts the found documents in the parent document" do
          expect(eager.first.ivar(:posts)).to eq([post])
        end

        it "does not set documents not found" do
          expect(eager.last.ivar(:posts)).to be_falsey
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

      let!(:eager) do
        Movie.includes(:ratings).first
      end

      it "puts the found documents in the parent document" do
        expect(eager.ivar(:ratings)).to eq([rating])
      end

      it "does not query when touching the association" do
        expect_query(0) do
          expect(eager.ratings).to eq([rating])
        end
      end
    end
  end
end
