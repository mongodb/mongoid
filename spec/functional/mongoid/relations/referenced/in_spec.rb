require "spec_helper"

describe Mongoid::Relations::Referenced::In do

  before do
    [ Person, Game, Post, Bar, Agent, Comment, Movie, Account ].map(&:delete_all)
  end

  let(:person) do
    Person.create(:ssn => "555-55-1111")
  end

  describe "#=" do

    context "when the inverse relation has no reference defined" do

      let(:agent) do
        Agent.new(:title => "007")
      end

      let(:game) do
        Game.new(:name => "Donkey Kong")
      end

      before do
        agent.game = game
      end

      it "sets the relation" do
        agent.game.should == game
      end

      it "sets the foreign_key" do
        agent.game_id.should == game.id
      end
    end

    context "when referencing a document from an embedded document" do

      let(:person) do
        Person.create(:ssn => "111-11-1111")
      end

      let(:address) do
        person.addresses.create(:street => "Wienerstr")
      end

      let(:account) do
        Account.create(:name => "1", :number => 1000000)
      end

      before do
        address.account = account
      end

      it "sets the relation" do
        address.account.should == account
      end

      it "does not erase the metadata" do
        address.metadata.should_not be_nil
      end

      it "allows saving of the embedded document" do
        address.save.should be_true
      end
    end

    context "when the parent is a references one" do

      context "when the relation is not polymorphic" do

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

      context "when the relation is not polymorphic" do

        context "when the child is a new record" do

          let(:bar) do
            Bar.new
          end

          let(:rating) do
            Rating.new
          end

          before do
            rating.ratable = bar
          end

          it "sets the target of the relation" do
            rating.ratable.target.should == bar
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should == bar.id
          end

          it "sets the base on the inverse relation" do
            bar.rating.should == rating
          end

          it "sets the same instance on the inverse relation" do
            bar.rating.should eql(rating)
          end

          it "does not save the target" do
            bar.should_not be_persisted
          end
        end

        context "when the child is not a new record" do

          let(:bar) do
            Bar.new
          end

          let(:rating) do
            Rating.create
          end

          before do
            rating.ratable = bar
          end

          it "sets the target of the relation" do
            rating.ratable.target.should == bar
          end

          it "sets the foreign key of the relation" do
            rating.ratable_id.should == bar.id
          end

          it "sets the base on the inverse relation" do
            bar.rating.should == rating
          end

          it "sets the same instance on the inverse relation" do
            bar.rating.should eql(rating)
          end

          it "does not saves the target" do
            bar.should_not be_persisted
          end
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

          it "does not saves the target" do
            movie.should_not be_persisted
          end
        end
      end
    end
  end

  describe "#= nil" do

    context "when the inverse relation has no reference defined" do

      let(:agent) do
        Agent.new(:title => "007")
      end

      let(:game) do
        Game.new(:name => "Donkey Kong")
      end

      before do
        agent.game = game
        agent.game = nil
      end

      it "removes the relation" do
        agent.game.should be_nil
      end

      it "removes the foreign_key" do
        agent.game_id.should be_nil
      end
    end

    context "when the parent is a references one" do

      context "when the relation is not polymorphic" do

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
            Person.create(:ssn => "437-11-1112")
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

          it "does not delete the child" do
            game.should_not be_destroyed
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when the parent is a new record" do

          let(:bar) do
            Bar.new
          end

          let(:rating) do
            Rating.new
          end

          before do
            rating.ratable = bar
            rating.ratable = nil
          end

          it "sets the relation to nil" do
            rating.ratable.should be_nil
          end

          it "removed the inverse relation" do
            bar.rating.should be_nil
          end

          it "removes the foreign key value" do
            rating.ratable_id.should be_nil
          end
        end

        context "when the parent is not a new record" do

          let(:bar) do
            Bar.new(:ssn => "437-11-1112")
          end

          let(:rating) do
            Rating.create
          end

          before do
            rating.ratable = bar
            rating.ratable = nil
          end

          it "sets the relation to nil" do
            rating.ratable.should be_nil
          end

          it "removed the inverse relation" do
            bar.rating.should be_nil
          end

          it "removes the foreign key value" do
            rating.ratable_id.should be_nil
          end
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

  describe ".eager_load" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    context "when the relation is not polymorphic" do

      let!(:person) do
        Person.create(:ssn => "243-12-5243")
      end

      let!(:post) do
        person.posts.create(:title => "testing")
      end

      let(:metadata) do
        Post.relations["person"]
      end

      let(:eager) do
        described_class.eager_load(metadata, Post.all)
      end

      let!(:map) do
        Mongoid::IdentityMap.get(Person, person.id)
      end

      it "puts the document in the identity map" do
        map.should eq(person)
      end
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        Rating.relations["ratable"]
      end

      it "raises an error" do
        expect {
          described_class.eager_load(metadata, Rating.all)
        }.to raise_error(Mongoid::Errors::EagerLoad)
      end
    end
  end

  context "when the relation is self referencing" do

    let(:game_one) do
      Game.new(:name => "Diablo")
    end

    let(:game_two) do
      Game.new(:name => "Warcraft")
    end

    context "when setting the parent" do

      before do
        game_one.parent = game_two
      end

      it "sets the parent" do
        game_one.parent.should eq(game_two)
      end

      it "does not set the parent recursively" do
        game_two.parent.should be_nil
      end
    end
  end

  context "when replacing the relation with another" do

    let!(:person) do
      Person.create(:ssn => "321-99-8888")
    end

    let!(:post) do
      Post.create(:title => "test")
    end

    let!(:game) do
      person.create_game(:name => "Tron")
    end

    before do
      post.person = game.person
      post.save
    end

    it "clones the relation" do
      post.person.should eq(person)
    end

    it "sets the foreign key" do
      post.person_id.should eq(person.id)
    end

    it "does not remove the previous relation" do
      game.person.should eq(person)
    end

    it "does not remove the previous foreign key" do
      game.person_id.should eq(person.id)
    end

    context "when reloading" do

      before do
        post.reload
        game.reload
      end

      it "persists the relation" do
        post.reload.person.should eq(person)
      end

      it "persists the foreign key" do
        post.reload.person_id.should eq(game.person_id)
      end

      it "does not remove the previous relation" do
        game.person.should eq(person)
      end

      it "does not remove the previous foreign key" do
        game.person_id.should eq(person.id)
      end
    end
  end

  context "when the document belongs to a has one and has many" do

    let(:movie) do
      Movie.create(:name => "Infernal Affairs")
    end

    let(:account) do
      Account.create(:name => "Leung")
    end

    context "when creating the document" do

      let(:comment) do
        Comment.create(:movie => movie, :account => account)
      end

      it "sets the correct has one" do
        comment.account.should eq(account)
      end

      it "sets the correct has many" do
        comment.movie.should eq(movie)
      end
    end
  end

  context "when reloading the relation" do

    let!(:person_one) do
      Person.create(:ssn => "243-41-9678", :title => "Mr.")
    end

    let!(:person_two) do
      Person.create(:ssn => "243-41-9699", :title => "Sir")
    end

    let!(:game) do
      Game.create(:name => "Starcraft 2")
    end

    before do
      game.person = person_one
      game.save
    end

    context "when the relation references the same document" do

      before do
        Person.collection.update(
          { :_id => person_one.id }, { "$set" => { :title => "Madam" }}
        )
      end

      let(:reloaded) do
        game.person(true)
      end

      it "reloads the document from the database" do
        reloaded.title.should eq("Madam")
      end

      it "sets a new document instance" do
        reloaded.should_not equal(person_one)
      end
    end

    context "when the relation references a different document" do

      before do
        game.person_id = person_two.id
        game.save
      end

      let(:reloaded) do
        game.person(true)
      end

      it "reloads the new document from the database" do
        reloaded.title.should eq("Sir")
      end

      it "sets a new document instance" do
        reloaded.should_not equal(person_one)
      end
    end
  end
end
