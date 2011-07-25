require "spec_helper"

describe Mongoid::Relations::Referenced::One do

  before do
    [ Person, Game, Bar ].map(&:delete_all)
  end

  describe "#=" do

    context "when the relationship is an illegal embedded reference" do

      let(:game) do
        Game.new
      end

      let(:video) do
        Video.new
      end

      it "raises a mixed relation error" do
        expect {
          game.video = video
        }.to raise_error(Mongoid::Errors::MixedRelations)
      end
    end

    context "when the relation is not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:game) do
          Game.new
        end

        before do
          person.game = game
        end

        it "sets the target of the relation" do
          person.game.target.should == game
        end

        it "sets the foreign key on the relation" do
          game.person_id.should == person.id
        end

        it "sets the base on the inverse relation" do
          game.person.should == person
        end

        it "sets the same instance on the inverse relation" do
          game.person.should eql(person)
        end

        it "does not save the target" do
          game.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create(:ssn => "437-11-1112")
        end

        let(:game) do
          Game.new
        end

        before do
          person.game = game
        end

        it "sets the target of the relation" do
          person.game.target.should == game
        end

        it "sets the foreign key of the relation" do
          game.person_id.should == person.id
        end

        it "sets the base on the inverse relation" do
          game.person.should == person
        end

        it "sets the same instance on the inverse relation" do
          game.person.should eql(person)
        end

        it "saves the target" do
          game.should be_persisted
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
          bar.rating = rating
        end

        it "sets the target of the relation" do
          bar.rating.target.should == rating
        end

        it "sets the foreign key on the relation" do
          rating.ratable_id.should == bar.id
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should == bar
        end

        it "sets the same instance on the inverse relation" do
          rating.ratable.should eql(bar)
        end

        it "does not save the target" do
          rating.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:bar) do
          Bar.create
        end

        let(:rating) do
          Rating.new
        end

        before do
          bar.rating = rating
        end

        it "sets the target of the relation" do
          bar.rating.target.should == rating
        end

        it "sets the foreign key of the relation" do
          rating.ratable_id.should == bar.id
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should == bar
        end

        it "sets the same instance on the inverse relation" do
          rating.ratable.should eql(bar)
        end

        it "saves the target" do
          rating.should be_persisted
        end
      end
    end
  end

  describe "#= nil" do

    context "when the relation is not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:game) do
          Game.new
        end

        before do
          person.game = game
          person.game = nil
        end

        it "sets the relation to nil" do
          person.game.should be_nil
        end

        it "removed the inverse relation" do
          game.person.should be_nil
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
          Game.new
        end

        before do
          person.game = game
          person.game = nil
        end

        it "sets the relation to nil" do
          person.game.should be_nil
        end

        it "removed the inverse relation" do
          game.person.should be_nil
        end

        it "removes the foreign key value" do
          game.person_id.should be_nil
        end

        it "deletes the target from the database" do
          game.should be_destroyed
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
          bar.rating = rating
          bar.rating = nil
        end

        it "sets the relation to nil" do
          bar.rating.should be_nil
        end

        it "removed the inverse relation" do
          rating.ratable.should be_nil
        end

        it "removes the foreign key value" do
          rating.ratable_id.should be_nil
        end
      end

      context "when the parent is not a new record" do

        let(:bar) do
          Bar.create
        end

        let(:rating) do
          Rating.new
        end

        before do
          bar.rating = rating
          bar.rating = nil
        end

        it "sets the relation to nil" do
          bar.rating.should be_nil
        end

        it "removed the inverse relation" do
          rating.ratable.should be_nil
        end

        it "removes the foreign key value" do
          rating.ratable_id.should be_nil
        end

        it "deletes the target from the database" do
          rating.should be_destroyed
        end
      end
    end
  end

  describe "#build_#\{name}" do

    context "when the relationship is an illegal embedded reference" do

      let(:game) do
        Game.new
      end

      it "raises a mixed relation error" do
        expect {
          game.build_video(:title => "Tron")
        }.to raise_error(Mongoid::Errors::MixedRelations)
      end
    end

    context "when the relation is not polymorphic" do

      context "when using object ids" do

        let(:person) do
          Person.create
        end

        let(:game) do
          person.build_game(:score => 50)
        end

        it "returns a new document" do
          game.score.should == 50
        end

        it "sets the foreign key on the document" do
          game.person_id.should == person.id
        end

        it "sets the inverse relation" do
          game.person.should == person
        end

        it "does not save the built document" do
          game.should_not be_persisted
        end
      end

      context "when providing no attributes" do

        let(:person) do
          Person.create
        end

        let(:game) do
          person.build_game
        end

        it "sets the foreign key on the document" do
          game.person_id.should == person.id
        end

        it "sets the inverse relation" do
          game.person.should == person
        end

        it "does not save the built document" do
          game.should_not be_persisted
        end
      end

      context "when providing nil attributes" do

        let(:person) do
          Person.create
        end

        let(:game) do
          person.build_game(nil)
        end

        it "sets the foreign key on the document" do
          game.person_id.should == person.id
        end

        it "sets the inverse relation" do
          game.person.should == person
        end

        it "does not save the built document" do
          game.should_not be_persisted
        end
      end
    end

    context "when the relation is polymorphic" do

      context "when using object ids" do

        let(:bar) do
          Bar.create
        end

        let(:rating) do
          bar.build_rating(:value => 5)
        end

        it "returns a new document" do
          rating.value.should == 5
        end

        it "sets the foreign key on the document" do
          rating.ratable_id.should == bar.id
        end

        it "sets the inverse relation" do
          rating.ratable.should == bar
        end

        it "does not save the built document" do
          rating.should_not be_persisted
        end
      end
    end
  end

  describe "#create_#\{name}" do

    context "when the relationship is an illegal embedded reference" do

      let(:game) do
        Game.new
      end

      it "raises a mixed relation error" do
        expect {
          game.create_video(:title => "Tron")
        }.to raise_error(Mongoid::Errors::MixedRelations)
      end
    end

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let(:game) do
        person.create_game(:score => 50)
      end

      it "returns a new document" do
        game.score.should == 50
      end

      it "sets the foreign key on the document" do
        game.person_id.should == person.id
      end

      it "sets the inverse relation" do
        game.person.should == person
      end

      it "saves the document" do
        game.should be_persisted
      end
    end

    context "when providing no attributes" do

      let(:person) do
        Person.create
      end

      let(:game) do
        person.create_game
      end

      it "sets the foreign key on the document" do
        game.person_id.should == person.id
      end

      it "sets the inverse relation" do
        game.person.should == person
      end

      it "saves the document" do
        game.should be_persisted
      end
    end

    context "when providing nil attributes" do

      let(:person) do
        Person.create
      end

      let(:game) do
        person.create_game(nil)
      end

      it "sets the foreign key on the document" do
        game.person_id.should == person.id
      end

      it "sets the inverse relation" do
        game.person.should == person
      end

      it "saves the document" do
        game.should be_persisted
      end
    end

    context "when the relation is polymorphic" do

      let(:bar) do
        Bar.create
      end

      let(:rating) do
        bar.create_rating(:value => 5)
      end

      it "returns a new document" do
        rating.value.should == 5
      end

      it "sets the foreign key on the document" do
        rating.ratable_id.should == bar.id
      end

      it "sets the inverse relation" do
        rating.ratable.should == bar
      end

      it "saves the document" do
        rating.should be_persisted
      end
    end
  end

  describe "#nullify" do

    let(:person) do
      Person.create(:ssn => "777-77-7777")
    end

    let!(:game) do
      person.create_game(:name => "Starcraft II")
    end

    context "when the instance has been set" do

      before do
        person.game.nullify
      end

      it "removes the foreign key from the target" do
        game.person_id.should be_nil
      end

      it "removes the reference from the target" do
        game.person.should be_nil
      end

      it "removes the reference from the base" do
        person.game.should be_nil
      end
    end

    context "when the instance has been reloaded" do

      let(:from_db) do
        Person.find(person.id)
      end

      let(:game_reloaded) do
        Game.find(game.id)
      end

      before do
        from_db.game.nullify
      end

      it "removes the foreign key from the target" do
        game_reloaded.person_id.should be_nil
      end

      it "removes the reference from the target" do
        game_reloaded.person.should be_nil
      end

      it "removes the reference from the base" do
        from_db.game.should be_nil
      end
    end
  end
end
