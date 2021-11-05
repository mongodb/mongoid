# frozen_string_literal: true

require "spec_helper"
require_relative '../has_many_models'

describe Mongoid::Association::Referenced::HasMany::Eager do

  describe ".grouped_docs" do

    let(:docs) do
      Person.all.to_a
    end

    let(:person) do
      Person.create!
    end

    let(:association) do
      Person.reflect_on_association(:posts)
    end

    let(:eager) do
      described_class.new([association], docs).tap do |b|
        b.send(:shift_association)
      end
    end

    before do
      Post.create!(person: person)
    end

    it "aggregates by the parent primary key" do
      expect(eager.send(:grouped_docs).keys).to eq([person.id])
    end
  end

  describe ".set_on_parent" do

    let(:docs) do
      Person.all.to_a
    end

    let(:person) do
      Person.create!
    end

    let(:association) do
      Person.reflect_on_association(:posts)
    end

    let(:eager) do
      described_class.new([association], docs).tap do |b|
        b.send(:shift_association)
      end
    end

    before do
      Post.create!(person: person)
      eager
    end

    it "sets the relation into the parent" do
      docs.each do |doc|
        expect(doc).to receive(:__build__).once.with(:posts, :foo, association)
      end
      eager.send(:set_on_parent, person.id, :foo)
    end

    context 'when able to make query count assertions' do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      it "doesnt call an extra query" do
        expect_query(0) do
          eager.send(:set_on_parent, person.id, :foo)
        end
      end
    end
  end

  describe ".includes" do

    let(:person) do
      Person.create!
    end

    context "when including the has_many relation" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      before do
        3.times { Drug.create!(person: person) }
        Drug.create!(person: Person.create!)
      end

      it "queries twice" do

         expect_query(2) do
          Person.all.includes(:drugs).each do |person|
            expect(person.drugs.entries).to_not be_empty
          end
        end
      end

      it "does not query when accessing the base on each document" do
        persons = Person.all.includes(:drugs).to_a
        expect_query(0) do
          persons.each do |person|
            person.drugs.collect(&:person)
          end
        end
      end
    end

    context "when the relation is not polymorphic" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      context "when the eager load has returned documents" do

        let!(:post) do
          person.posts.create!(title: "testing")
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

        it "does not query when accessing the base on each document" do
          expect_query(0) do
            eager.posts.collect(&:person)
          end
        end
      end

      context "when the eager load has not returned documents" do

        before { person }

        let!(:eager) do
          Person.includes(:posts).last
        end

        it "does not set anything on the parent" do
          expect(eager.ivar(:posts)).to be_empty
        end

        it "has an empty proxy" do
          expect(eager.posts).to eq([])
        end

        it "does not query when touching the association" do
          expect_query(0) do
            eager.posts.entries
          end
        end

        it "returns the proxy" do
          expect do
            eager.posts.create!(title: "testing")
          end.to_not raise_error
        end
      end

      context "when the eager load has not returned documents for some" do

        let!(:person_one) do
          person
        end

        let!(:person_two) do
          Person.create!(username: "durran")
        end

        let!(:post) do
          person_one.posts.create!(title: "testing")
        end

        let!(:eager) do
          Person.includes(:posts).asc(:username).to_a
        end

        it "puts the found documents in the parent document" do
          expect(eager.first.ivar(:posts)).to eq([post])
        end

        it "does not set documents not found" do
          expect(eager.last.ivar(:posts)).to be_empty
        end
      end

      context "when the child has a default scope" do

        let(:criteria) do
          Exhibitor.where(:status.ne => "removed")
        end

        let(:exhibitorPresent) do
          Exhibitor.create!(status: "present")
        end

        let(:exhibitorRemoved) do
          Exhibitor.create!(status: "removed")
        end

        let(:exhibitionIncludesExhibitors) do
          Exhibition.includes(:exhibitors).first
        end

        before do
          Exhibitor.default_scope ->{ criteria }
          exhibition = Exhibition.create!
          exhibition.exhibitors << exhibitorPresent
          exhibition.exhibitors << exhibitorRemoved
          exhibitionIncludesExhibitors
        end

        after do
          Exhibitor.default_scoping = nil
        end

        it "does not send another query when the children are accessed" do
          expect_query(0) do
            expect(exhibitionIncludesExhibitors.exhibitors).to eq( [exhibitorPresent] )
          end
        end
      end
    end

    context "when the relation is polymorphic" do

      let!(:movie) do
        Movie.create!(name: "Bladerunner")
      end

      let!(:rating) do
        movie.ratings.create!(value: 10)
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

    context "when the association has scope" do
      let!(:trainer1) { HmmTrainer.create!(name: 'Dave') }
      let!(:trainer2) { HmmTrainer.create!(name: 'Ash') }
      let!(:animal1) { HmmAnimal.create!(taxonomy: 'reptile', trainer: trainer1) }
      let!(:animal2) { HmmAnimal.create!(taxonomy: 'bird', trainer: trainer1) }

      let(:eager) do
        HmmTrainer.includes(:animals).where(_id: trainer1._id).to_a.first
      end

      it 'eager loads the included docs' do
        expect(eager.animals._loaded).to eq(animal1._id => animal1)
        expect(eager.animals).to eq [animal1]
      end
    end
  end
end
