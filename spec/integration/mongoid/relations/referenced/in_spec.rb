require "spec_helper"

describe Mongoid::Relations::Referenced::In do

  before do
    [ Person, Game, Post ].map(&:delete_all)
  end

  describe "#=" do

    context "when the parent is a references one" do

      context "when the child is a new record" do

        let(:person) do
          Person.new
        end

        let(:game) do
          Game.new
        end

        before do
          game.person = person
        end

        it "sets the target of the relation" do
          game.person.target.should == person
        end

        it "sets the foreign key on the relation" do
          game.person_id.should == person.id
        end

        it "sets the base on the inverse relation" do
          person.game.should == game
        end

        it "sets the same instance on the inverse relation" do
          person.game.should eql(game)
        end

        it "does not save the target" do
          person.should_not be_persisted
        end
      end

      context "when the child is not a new record" do

        let(:person) do
          Person.new(:ssn => "437-11-1112")
        end

        let(:game) do
          Game.create
        end

        before do
          game.person = person
        end

        it "sets the target of the relation" do
          game.person.target.should == person
        end

        it "sets the foreign key of the relation" do
          game.person_id.should == person.id
        end

        it "sets the base on the inverse relation" do
          person.game.should == game
        end

        it "sets the same instance on the inverse relation" do
          person.game.should eql(game)
        end

        it "does not saves the target" do
          person.should_not be_persisted
        end
      end
    end

    context "when the parent is a references many" do

      context "when the relation is not polymorphic" do

        context "when the child is a new record" do

          let(:person) do
            Person.new
          end

          let(:post) do
            Post.new
          end

          before do
            post.person = person
          end

          it "sets the target of the relation" do
            post.person.target.should == person
          end

          it "sets the foreign key on the relation" do
            post.person_id.should == person.id
          end

          it "sets the base on the inverse relation" do
            person.posts.should == [ post ]
          end

          it "sets the same instance on the inverse relation" do
            person.posts.first.should eql(post)
          end

          it "does not save the target" do
            person.should_not be_persisted
          end
        end

        context "when the child is not a new record" do

          let(:person) do
            Person.new(:ssn => "437-11-1112")
          end

          let(:post) do
            Post.create
          end

          before do
            post.person = person
          end

          it "sets the target of the relation" do
            post.person.target.should == person
          end

          it "sets the foreign key of the relation" do
            post.person_id.should == person.id
          end

          it "sets the base on the inverse relation" do
            person.posts.should == [ post ]
          end

          it "sets the same instance on the inverse relation" do
            person.posts.first.should eql(post)
          end

          it "does not saves the target" do
            person.should_not be_persisted
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when the child is a new record" do

          let(:movie) do
            Movie.new
          end

          let(:rating) do
            Rating.new
          end

          before do
            rating.ratable = movie
          end

          it "sets the target of the relation" do
            rating.ratable.target.should == movie
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should == movie.id
          end

          it "sets the base on the inverse relation" do
            movie.ratings.should == [ rating ]
          end

          it "does not save the target" do
            movie.should_not be_persisted
          end
        end

        context "when the child is not a new record" do

          let(:movie) do
            Movie.new(:ssn => "437-11-1112")
          end

          let(:rating) do
            Rating.create
          end

          before do
            rating.ratable = movie
          end

          it "sets the target of the relation" do
            rating.ratable.target.should == movie
          end

          it "sets the foreign key of the relation" do
            rating.ratable_id.should == movie.id
          end

          it "sets the base on the inverse relation" do
            movie.ratings.should == [ rating ]
          end

          it "does not saves the target" do
            movie.should_not be_persisted
          end
        end
      end
    end
  end

  describe "#= nil" do

    context "when the parent is a references one" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:game) do
          Game.new
        end

        before do
          game.person = person
          game.person = nil
        end

        it "sets the relation to nil" do
          game.person.should be_nil
        end

        it "removed the inverse relation" do
          person.game.should be_nil
        end

        it "removes the foreign key value" do
          game.person_id.should be_nil
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.new(:ssn => "437-11-1112")
        end

        let(:game) do
          Game.create
        end

        before do
          game.person = person
          game.person = nil
        end

        it "sets the relation to nil" do
          game.person.should be_nil
        end

        it "removed the inverse relation" do
          person.game.should be_nil
        end

        it "removes the foreign key value" do
          game.person_id.should be_nil
        end
      end
    end

    context "when the parent is a references many" do

      context "when the relation is not polymorphic" do

        context "when the parent is a new record" do

          let(:person) do
            Person.new
          end

          let(:post) do
            Post.new
          end

          before do
            post.person = person
            post.person = nil
          end

          it "sets the relation to nil" do
            post.person.should be_nil
          end

          it "removed the inverse relation" do
            person.posts.should be_empty
          end

          it "removes the foreign key value" do
            post.person_id.should be_nil
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.new(:ssn => "437-11-1112")
          end

          let(:post) do
            Post.create
          end

          before do
            post.person = person
            post.person = nil
          end

          it "sets the relation to nil" do
            post.person.should be_nil
          end

          it "removed the inverse relation" do
            person.posts.should be_empty
          end

          it "removes the foreign key value" do
            post.person_id.should be_nil
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when the parent is a new record" do

          let(:movie) do
            Movie.new
          end

          let(:rating) do
            Rating.new
          end

          before do
            rating.ratable = movie
            rating.ratable = nil
          end

          it "sets the relation to nil" do
            rating.ratable.should be_nil
          end

          it "removed the inverse relation" do
            movie.ratings.should be_empty
          end

          it "removes the foreign key value" do
            rating.ratable_id.should be_nil
          end
        end

        context "when the parent is not a new record" do

          let(:movie) do
            Movie.new(:ssn => "437-11-1112")
          end

          let(:rating) do
            Rating.create
          end

          before do
            rating.ratable = movie
            rating.ratable = nil
          end

          it "sets the relation to nil" do
            rating.ratable.should be_nil
          end

          it "removed the inverse relation" do
            movie.ratings.should be_empty
          end

          it "removes the foreign key value" do
            rating.ratable_id.should be_nil
          end
        end
      end
    end
  end
end
