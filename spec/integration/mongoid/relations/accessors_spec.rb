require "spec_helper"

describe Mongoid::Relations::Accessors do

  before do
    [ Movie, Rating ].each(&:delete_all)
  end

  describe "\#{getter}" do

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create(:title => "Inception")
      end

      let(:rating) do
        Rating.where(:value => 10).first
      end

      before do
        movie.ratings.create(:value => 10)
      end

      it "returns the correct type" do
        rating.ratable.should be_a(Movie)
      end
    end
  end
end
