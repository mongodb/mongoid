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

      context "when the relation is an embeds one" do

        context "when the relation is auto built" do

          let (:person) do
            Person.new
          end

          it "should automatically be built when the getter is called" do
            person.expects(:build_passport).once
            person.passport
          end

          it "should not be built when :autobuild option is false" do
            person.expects(:build_passport).never
            person.passport(:autobuild => false)
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

  describe "\#{getter}?" do

    context "when the relation is not persisted" do

      context "when the relation exists" do

        let(:person) do
          Person.new(
            :passport => Passport.new,
            :addresses => [Address.new]
          )
        end

        context "when it is a one relation" do

          it "returns true" do
            person.passport?.should == true
          end
        end

        context "when it is a many relation" do

          it "returns true" do
            person.addresses?.should == true
          end
        end
      end

      context "when the relation does not exist" do

        let(:person) do
          Person.new
        end

        context "when it is a one relation" do

          it "returns false" do
            person.passport?.should == false
          end
        end

        context "when it is a many relation" do

          it "returns false" do
            person.addresses?.should == false
          end
        end
      end
    end

    context "when the relation is persisted" do

      context "when the relation exists" do

        let(:person) do
          Person.create(
            :passport => Passport.new,
            :addresses => [Address.new]
          )
        end

        context "when it is a one relation" do

          it "returns true" do
            person.passport?.should == true
          end
        end

        context "when it is a many relation" do

          it "returns true" do
            person.addresses?.should == true
          end
        end
      end

      context "when the relation does not exist" do

        let(:person) do
          Person.create
        end

        context "when it is a one relation" do

          it "returns false" do
            person.passport?.should == false
          end
        end

        context "when it is a many relation" do

          it "returns false" do
            person.addresses?.should == false
          end
        end
      end
    end

    context "when the relation is auto built" do

      let(:person) do
        Person.new
      end

      it "does not build the unaccessed relation" do
        person.expects(:build_passport).never
        person.passport?
      end
    end
  end

  context "when setting relations to empty values" do

    context "when the document is a referenced in" do

      let(:post) do
        Post.new
      end

      context "when setting the relation directly" do

        before do
          post.person = ""
        end

        it "converts them to nil" do
          post.person.should be_nil
        end
      end

      context "when setting the foreign key" do

        before do
          post.person_id = ""
        end

        it "converts it to nil" do
          post.person_id.should be_nil
        end
      end
    end

    context "when the document is a references one" do

      let(:person) do
        Person.new
      end

      context "when setting the relation directly" do

        before do
          person.game = ""
        end

        it "converts them to nil" do
          person.game.should be_nil
        end
      end

      context "when setting the foreign key" do

        let(:game) do
          Game.new
        end

        before do
          game.person_id = ""
        end

        it "converts it to nil" do
          game.person_id.should be_nil
        end
      end

      context "when the document is auto built" do

        it "should automatically be built when the getter is called" do
          person.expects(:build_book).once
          person.book
        end

        it "should not be built when :autobuild option is false" do
          person.expects(:build_book).never
          person.book(:autobuild => false)
        end
      end
    end

    context "when the document is a references many" do

      let(:person) do
        Person.new
      end

      context "when setting the foreign key" do

        let(:post) do
          Post.new
        end

        before do
          post.person_id = ""
        end

        it "converts it to nil" do
          post.person.should be_nil
        end
      end
    end

    context "when the document is a references many to many" do

      let(:person) do
        Person.new
      end

      context "when setting the foreign key" do

        before do
          person.preference_ids = [ "", "" ]
        end

        it "does not add them" do
          person.preference_ids.should be_empty
        end
      end
    end

    context "when the document is a referenced in" do

      let(:book) do
        Book.new
      end

      it "should automatically be built when the getter is called" do
        book.expects(:build_person).once
        book.person
      end

      it "should not build when :autobuild option is false" do
        book.expects(:build_person).never
        book.person(:autobuild => false)
      end
    end
  end
end
