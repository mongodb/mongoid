# frozen_string_literal: true

require "spec_helper"
require_relative '../has_many_models'
require_relative '../has_one_models'

describe Mongoid::Association::Referenced::BelongsTo::Eager do

  describe ".grouped_docs" do

    let(:docs) do
      Post.all.to_a
    end

    let(:person) do
      Person.create!
    end

    let(:association) do
      Post.reflect_on_association(:person)
    end

    let(:eager) do
      described_class.new([association], docs).tap do |b|
        b.send(:shift_association)
      end
    end

    before do
      Post.create!(person: person)
    end

    it "aggregates by the parent id" do
      expect(eager.send(:grouped_docs).keys).to eq([person.id])
    end
  end

  describe ".set_on_parent" do

    let(:docs) do
      Post.all.to_a
    end

    let(:person) do
      Person.create!
    end

    let(:association) do
      Post.reflect_on_association(:person)
    end

    let(:eager) do
      described_class.new([association], docs).tap do |b|
        b.send(:shift_association)
      end
    end

    before do
      Post.create!(person: person)
    end

    it "sets the association into the parent" do
      docs.each do |doc|
        expect(doc).to receive(:set_relation).with(:person, :foo)
      end
      eager.send(:set_on_parent, person.id, :foo)
    end
  end

  describe ".includes" do

    let(:person) do
      Person.create!
    end

    before do
      3.times { |i| Account.create!(person: person, name: "savings#{i}") }
    end

    context "when including the belongs_to association" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      it "queries twice" do

        expect_query(2) do
          Account.all.includes(:person).each do |account|
            expect(account.person).to_not be_nil
          end
        end
      end
    end

    context "when the association is not polymorphic" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      let(:eager) do
        Post.includes(:person).last
      end

      context "when the eager load has returned documents" do

        let!(:post) do
          person.posts.create!(title: "testing")
        end

        before { eager }

        it "puts the documents in the parent document" do
          expect(eager.ivar(:person)).to eq(person)
        end

        it "does not query when touching the association" do
          expect_no_queries do
            expect(eager.person).to eq(person)
          end
        end

        it "does not query when updating the association" do
          expect_no_queries do
            eager.person.username = "arthurnn"
          end
        end
      end

      context "when the eager load has not returned documents" do

        let!(:post) do
          Post.create!(title: "testing")
        end

        before { eager }

        it "does not set anything on the parent" do
          expect(eager.ivar(:person)).to be nil
        end

        it "has a nil association" do
          expect(eager.person).to be nil
        end
      end
    end

    context "when the association is polymorphic" do

      context "without namespaces" do

        let!(:stand_alone_rating) do
          Rating.create!(value: 7)
        end

        let!(:bar) do
          Bar.create!(name: "FooBar")
        end

        let(:bar_rating) do
          bar.create_rating(value: 5)
        end

        let!(:movie) do
          Movie.create!(name: "Bladerunner")
        end

        let(:movie_rating) do
          movie.ratings.create!(value: 10)
        end

        let(:eager) do
          Rating.includes(:ratable).entries
        end

        context "when the eager load has returned documents" do

          before do
            bar_rating
            movie_rating
            eager
          end

          it "puts the documents in the parent document" do
            expect(eager.map { |e| e.ivar(:ratable) }).to eq([nil, bar, movie])
          end

          it "does not query when touching the association" do
            expect_no_queries do
              expect(eager.map(&:ratable)).to eq([nil, bar, movie])
            end
          end

          it "does not query when updating the association" do
            expect_no_queries do
              eager.last.ratable.name = "Easy rider"
            end
          end
        end

        context "when the eager load has not returned documents" do

          before { eager }

          it "does not set anything on the parent" do
            expect(eager.map { |e| e.ivar(:ratable) }).to all(be nil)
          end

          it "has a nil association" do
            expect(eager.map(&:ratable)).to all(be nil)
          end
        end
      end

      context "with namespaces" do

        let!(:stand_alone_review) do
          Publication::Review.create!(summary: "awful")
        end

        let!(:encyclopedia) do
          Publication::Encyclopedia.create!(title: "Encyclopedia Britannica")
        end

        let(:encyclopedia_review) do
          encyclopedia.reviews.create!(summary: "inspiring")
        end

        let!(:pull_request) do
          Coding::PullRequest.create!(title: "Add eager loading for polymorphic belongs_to associations")
        end

        let(:pull_request_review) do
          pull_request.reviews.create!(summary: "Looks good to me")
        end

        let(:eager) do
          Publication::Review.includes(:reviewable).entries
        end

        context "when the eager load has returned documents" do

          before do
            encyclopedia_review
            pull_request_review
            eager
          end

          it "puts the documents in the parent document" do
            expect(eager.map { |e| e.ivar(:reviewable) }).to eq([nil, encyclopedia, pull_request])
          end

          it "does not query when touching the association" do
            expect_no_queries do
              expect(eager.map(&:reviewable)).to eq([nil, encyclopedia, pull_request])
            end
          end

          it "does not query when updating the association" do
            expect_no_queries do
              eager.last.reviewable.title = "Load stuff eagerly"
            end
          end
        end

        context "when the eager load has not returned documents" do

          before { eager }

          it "does not set anything on the parent" do
            expect(eager.map { |e| e.ivar(:reviewable) }).to all(be nil)
          end

          it "has a nil association" do
            expect(eager.map(&:reviewable)).to all(be nil)
          end
        end
      end

      context 'when eager loading multiple associations' do
        let(:reviewable) do
          Publication::Encyclopedia.create!(title: "Encyclopedia Britannica")
        end

        let!(:reviewable_review) do
          Publication::Review.create!(summary: "awful",
            reviewable: reviewable)
        end

        let(:reviewer) do
          Dog.create!
        end

        let!(:reviewer_review) do
          Publication::Review.create!(summary: "okay",
            reviewer: reviewer)
        end

        let(:template) do
          Template.create!
        end

        let!(:template_review) do
          Publication::Review.create!(summary: "Looks good to me",
            template: template)
        end

        let(:eager) do
          Publication::Review.includes(:reviewable, :reviewer, :template).entries
        end

        it 'loads all associations eagerly' do
          loaded = expect_query(4) do
            eager
          end

          expect_no_queries do
            eager.map(&:reviewable).compact.should == [reviewable]
          end

          expect_no_queries do
            eager.map(&:reviewer).compact.should == [reviewer]
          end

          expect_no_queries do
            eager.map(&:template).compact.should == [template]
          end
        end
      end

      context 'when eager loading an association that has type but not value set' do

        let!(:reviewer_review) do
          Publication::Review.create!(summary: "okay",
            reviewer_type: 'Dog')
        end

        let(:eager) do
          Publication::Review.includes(:reviewable, :reviewer, :template).entries
        end

        it 'does not error' do
          eager.map(&:reviewer).should == [nil]
        end
      end
    end

    context "when the association has scope" do

      context 'when inverse of has_many' do
        let!(:trainer1) { HmmTrainer.create!(name: 'Dave') }
        let!(:trainer2) { HmmTrainer.create!(name: 'Ash') }
        let!(:animal1) { HmmAnimal.create!(taxonomy: 'reptile', trainer: trainer1) }
        let!(:animal2) { HmmAnimal.create!(taxonomy: 'bird', trainer: trainer2) }

        let(:eager) do
          HmmAnimal.includes(:trainer).to_a
        end

        it 'eager loads the included docs' do
          expect(eager[0].trainer).to eq trainer1
          expect(eager[1].trainer).to be_nil
        end
      end

      context 'when inverse of has_one' do
        let!(:trainer1) { HomTrainer.create!(name: 'Dave') }
        let!(:trainer2) { HomTrainer.create!(name: 'Ash') }
        let!(:animal1) { HomAnimal.create!(taxonomy: 'reptile', trainer: trainer1) }
        let!(:animal2) { HomAnimal.create!(taxonomy: 'bird', trainer: trainer2) }

        let(:eager) do
          HomAnimal.includes(:trainer).to_a
        end

        it 'eager loads the included docs' do
          expect(eager[0].trainer).to eq trainer1
          expect(eager[1].trainer).to be_nil
        end
      end
    end

    context "when setting the foreign key id directly" do

      it "works" do
        id = BSON::ObjectId.new
        game = Game.new(:person_id => id)
        expect(game.person_id).to eql(id)
      end
    end

    context "when all the values for the belongs_to association are nil" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      before do
        2.times { |i| HmmTicket.create!(person: nil) }
      end

      it "only queries once for the parent documents" do
        found_ticket = false
        expect_query(1) do
          HmmTicket.all.includes(:person).each do |ticket|
            expect(ticket.person).to eq nil
            found_ticket = true
          end
        end
        expect(found_ticket).to be true
      end
    end
  end
end
