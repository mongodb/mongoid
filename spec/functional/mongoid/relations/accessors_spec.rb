require "spec_helper"

describe Mongoid::Relations::Accessors do

  before do
    [ Book, Movie, Rating, Person, Preference, Game ].each(&:delete_all)
  end

  describe "\#{getter}" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create(:ssn => "666-66-6666")
      end

      context "when the relation is a many to many" do

        let!(:preference) do
          Preference.create(:name => "Setting")
        end

        before do
          person.preferences << Preference.last
        end

        context "when reloading the relation directly" do

          let(:preferences) do
            person.preferences(true)
          end

          it "reloads the correct documents" do
            preferences.should == [ preference ]
          end

          it "reloads a new instance" do
            preferences.first.should_not equal(preference)
          end
        end

        context "when reloading via the base document" do

          let(:preferences) do
            person.reload.preferences
          end

          it "reloads the correct documents" do
            preferences.should == [ preference ]
          end

          it "reloads a new instance" do
            preferences.first.should_not equal(preference)
          end
        end

        context "when performing a fresh find on the base" do

          let(:preferences) do
            Person.find(person.id).preferences
          end

          it "reloads the correct documents" do
            preferences.should == [ preference ]
          end
        end
      end

      context "when the relation is a many to one" do

        let!(:post) do
          Post.create(:title => "First!")
        end

        before do
          person.posts << Post.last
        end

        context "when reloading the relation directly" do

          let(:posts) do
            person.posts(true)
          end

          it "reloads the correct documents" do
            posts.should == [ post ]
          end

          it "reloads a new instance" do
            posts.first.should_not equal(post)
          end
        end

        context "when reloading via the base document" do

          let(:posts) do
            person.reload.posts
          end

          it "reloads the correct documents" do
            posts.should == [ post ]
          end

          it "reloads a new instance" do
            posts.first.should_not equal(post)
          end
        end

        context "when performing a fresh find on the base" do

          let(:posts) do
            Person.find(person.id).posts
          end

          it "reloads the correct documents" do
            posts.should == [ post ]
          end
        end
      end

      context "when the relation is a references one" do

        let!(:game) do
          Game.create(:name => "Centipeded")
        end

        before do
          person.game = Game.last
        end

        context "when reloading the relation directly" do

          let(:reloaded_game) do
            person.game(true)
          end

          it "reloads the correct documents" do
            reloaded_game.should == game
          end

          it "reloads a new instance" do
            reloaded_game.should_not equal(game)
          end
        end

        context "when reloading via the base document" do

          let(:reloaded_game) do
            person.reload.game
          end

          it "reloads the correct documents" do
            reloaded_game.should == game
          end

          it "reloads a new instance" do
            reloaded_game.should_not equal(game)
          end
        end

        context "when performing a fresh find on the base" do

          let(:reloaded_game) do
            Person.find(person.id).game
          end

          it "reloads the correct documents" do
            reloaded_game.should == game
          end
        end
      end
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create(:title => "Inception")
      end

      let(:book) do
        Book.create(:title => "Jurassic Park")
      end

      let!(:movie_rating) do
        movie.ratings.create(:value => 10)
      end

      let!(:book_rating) do
        book.create_rating(:value => 5)
      end

      context "when accessing a referenced in" do

        let(:rating) do
          Rating.where(:value => 10).first
        end

        it "returns the correct type" do
          rating.ratable.should be_a(Movie)
        end

        it "returns the correct document" do
          rating.ratable.should == movie
        end
      end

      context "when accessing a references many" do

        let(:ratings) do
          Movie.first.ratings
        end

        it "returns the correct documents" do
          ratings.should == [ movie_rating ]
        end
      end

      context "when accessing a references one" do

        let(:rating) do
          Book.first.rating
        end

        it "returns the correct document" do
          rating.should == book_rating
        end
      end
    end
  end
end
