require "spec_helper"

describe Mongoid::Relations::Accessors do

  before do
    [ Book, Movie, Rating ].each(&:delete_all)
  end

  describe "\#{getter}" do

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
