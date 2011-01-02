require "spec_helper"

describe Mongoid::Relations::Accessors do

  before do
    [ Book, Movie, Rating, Person, Preference ].each(&:delete_all)
  end

  describe "\#{getter}" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create(:ssn => "666-66-6666")
      end

      context "when reloading" do

        context "when reloading with a many to many" do

          let(:preference) do
            Preference.create(:name => "Setting")
          end

          let(:preferences) do
            person.preferences(true)
          end

          before do
            person.preferences << preference
          end

          it "reloads the correct documents" do
            preferences.should == [ preference ]
          end

          it "reloads a new instance" do
            preferences.first.should_not equal(preference)
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
