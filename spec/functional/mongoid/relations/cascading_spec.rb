require "spec_helper"

describe Mongoid::Relations::Cascading do

  before do
    [ Person, Post, Book, Movie, Rating ].each(&:delete_all)
  end

  [ :delete, :destroy ].each do |method|

    describe "##{method}" do

      context "when cascading removals" do

        context "when dependent is delete" do

          let(:person) do
            Person.create(:ssn => "609-00-4343")
          end

          let!(:post) do
            person.posts.create(:title => "Testing")
          end

          before do
            person.send(method)
          end

          it "deletes the associated documents" do
            expect {
              Post.find(post.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when dependent is destroy" do

          let(:person) do
            Person.create(:ssn => "609-00-4343")
          end

          let!(:game) do
            person.create_game(:name => "Pong")
          end

          before do
            person.send(method)
          end

          it "destroys the associated documents" do
            expect {
              Game.find(game.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when dependent is nullify" do

          context "when nullifying a references many" do

            let(:movie) do
              Movie.create(:title => "Bladerunner")
            end

            let!(:rating) do
              movie.ratings.create(:value => 10)
            end

            let(:from_db) do
              Rating.find(rating.id)
            end

            before do
              movie.send(method)
            end

            it "removes the references to the removed document" do
              from_db.ratable_id.should be_nil
            end
          end

          context "when nullifying a references one" do

            context "when the relation exists" do

              let(:book) do
                Book.create(:title => "Neuromancer")
              end

              let!(:rating) do
                book.create_rating(:value => 10)
              end

              let(:from_db) do
                Rating.find(rating.id)
              end

              before do
                book.send(method)
              end

              it "removes the references to the removed document" do
                from_db.ratable_id.should be_nil
              end
            end

            context "when the relation is nil" do

              let(:book) do
                Book.create(:title => "Neuromancer")
              end

              it "returns nil" do
                book.send(method).should be_true
              end
            end
          end

          context "when nullifying a many to many" do

            let(:person) do
              Person.create(:ssn => "009-00-0111")
            end

            let!(:preference) do
              person.preferences.create(:name => "Setting")
            end

            let(:from_db) do
              Preference.find(preference.id)
            end

            before do
              person.send(method)
            end

            it "removes the references from the removed document" do
              person.preference_ids.should_not include(preference.id)
            end

            it "removes the references to the removed document" do
              from_db.person_ids.should_not include(person.id)
            end
          end
        end
      end
    end
  end
end
