require "spec_helper"

describe Mongoid::Relations::Referenced::One do

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
          person.game.target.should eq(game)
        end

        it "sets the foreign key on the relation" do
          game.person_id.should eq(person.id)
        end

        it "sets the base on the inverse relation" do
          game.person.should eq(person)
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
          Person.create
        end

        let(:game) do
          Game.new
        end

        before do
          person.game = game
        end

        it "sets the target of the relation" do
          person.game.target.should eq(game)
        end

        it "sets the foreign key of the relation" do
          game.person_id.should eq(person.id)
        end

        it "sets the base on the inverse relation" do
          game.person.should eq(person)
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
          bar.rating.target.should eq(rating)
        end

        it "sets the foreign key on the relation" do
          rating.ratable_id.should eq(bar.id)
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should eq(bar)
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
          bar.rating.target.should eq(rating)
        end

        it "sets the foreign key of the relation" do
          rating.ratable_id.should eq(bar.id)
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should eq(bar)
        end

        it "sets the same instance on the inverse relation" do
          rating.ratable.should eql(bar)
        end

        it "saves the target" do
          rating.should be_persisted
        end
      end

      context "when replacing an existing persisted (dependent: :destroy) relation" do

        let!(:person) do
          Person.create
        end

        let!(:game) do
          person.create_game(name: "Starcraft")
        end

        context "with a new one created via the parent" do

          let!(:new_game) do
            person.create_game(name: "Starcraft 2")
          end

          it "sets the new relation on the parent" do
            person.game.should eq(new_game)
          end

          it "removes the old foreign key reference" do
            game.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            game.person.should be_nil
          end

          it "destroys the old child" do
            game.should be_destroyed
          end

          it "leaves the old child unpersisted" do
            game.persisted?.should be_false
          end

          it "leaves the new child persisted" do
            new_game.persisted?.should be_true
          end
        end

        context "with a new one built via the parent" do

          let!(:new_game) do
            person.build_game(name: "Starcraft 2")
          end

          it "sets the new relation on the parent" do
            person.game.should eq(new_game)
          end

          it "removes the old foreign key reference" do
            game.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            game.person.should be_nil
          end

          it "does not destroy the old child" do
            game.should_not be_destroyed
          end

          it "leaves the old child persisted" do
            game.persisted?.should be_true
          end

          it "leaves the new child unpersisted" do
            new_game.persisted?.should be_false
          end
        end
      end

      context "when replacing an existing unpersisted (dependent: :destroy) relation" do

        let!(:person) do
          Person.create
        end

        let!(:game) do
          person.build_game(name: "Starcraft")
        end

        context "with a new one created via the parent" do

          let!(:new_game) do
            person.create_game(name: "Starcraft 2")
          end

          it "sets the new relation on the parent" do
            person.game.should eq(new_game)
          end

          it "removes the old foreign key reference" do
            game.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            game.person.should be_nil
          end

          it "destroys the old child" do
            game.should be_destroyed
          end

          it "leaves the old child unpersisted" do
            game.persisted?.should be_false
          end

          it "leaves the new child persisted" do
            new_game.persisted?.should be_true
          end
        end

        context "with a new one built via the parent" do

          let!(:new_game) do
            person.build_game(name: "Starcraft 2")
          end

          it "sets the new relation on the parent" do
            person.game.should eq(new_game)
          end

          it "removes the old foreign key reference" do
            game.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            game.person.should be_nil
          end

          it "does not destroy the old child" do
            game.should_not be_destroyed
          end

          it "leaves the old child unpersisted" do
            game.persisted?.should be_false
          end

          it "leaves the new child unpersisted" do
            new_game.persisted?.should be_false
          end
        end
      end

      context "when replacing an existing persisted (dependent: :nullify) relation" do

        let!(:person) do
          Person.create
        end

        let!(:cat) do
          person.create_cat(name: "Cuddles")
        end

        context "with a new one created via the parent" do

          let!(:new_cat) do
            person.create_cat(name: "Brutus")
          end

          it "sets the new relation on the parent" do
            person.cat.should eq(new_cat)
          end

          it "removes the old foreign key reference" do
            cat.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            cat.person.should be_nil
          end

          it "does not destroy the old child" do
            cat.should_not be_destroyed
          end

          it "leaves the old child persisted" do
            cat.persisted?.should be_true
          end

          it "leaves the new child persisted" do
            new_cat.persisted?.should be_true
          end
        end

        context "with a new one built via the parent" do

          let!(:new_cat) do
            person.build_cat(name: "Brutus")
          end

          it "sets the new relation on the parent" do
            person.cat.should eq(new_cat)
          end

          it "removes the old foreign key reference" do
            cat.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            cat.person.should be_nil
          end

          it "does not destroy the old child" do
            cat.should_not be_destroyed
          end

          it "leaves the old child persisted" do
            cat.persisted?.should be_true
          end

          it "leaves the new child unpersisted" do
            new_cat.persisted?.should be_false
          end
        end
      end

      context "when replacing an existing unpersisted (dependent: :nullify) relation" do

        let!(:person) do
          Person.create
        end

        let!(:cat) do
          person.build_cat(name: "Cuddles")
        end

        context "with a new one created via the parent" do

          let!(:new_cat) do
            person.create_cat(name: "Brutus")
          end

          it "sets the new relation on the parent" do
            person.cat.should eq(new_cat)
          end

          it "removes the old foreign key reference" do
            cat.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            cat.person.should be_nil
          end

          it "does not destroy the old child" do
            cat.should_not be_destroyed
          end

          it "leaves the old child unpersisted" do
            cat.persisted?.should be_false
          end

          it "leaves the new child persisted" do
            new_cat.persisted?.should be_true
          end
        end

        context "with a new one built via the parent" do

          let!(:new_cat) do
            person.build_cat(name: "Brutus")
          end

          it "sets the new relation on the parent" do
            person.cat.should eq(new_cat)
          end

          it "removes the old foreign key reference" do
            cat.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            cat.person.should be_nil
          end

          it "does not destroy the old child" do
            cat.should_not be_destroyed
          end

          it "leaves the old child unpersisted" do
            cat.persisted?.should be_false
          end

          it "leaves the new child unpersisted" do
            new_cat.persisted?.should be_false
          end
        end
      end

      context "when replacing an existing relation with a new one" do

        let!(:person) do
          Person.create
        end

        context "when dependent is destroy" do

          let!(:game) do
            person.create_game(name: "Starcraft")
          end

          let!(:new_game) do
            Game.create(name: "Starcraft 2")
          end

          before do
            person.game = new_game
          end

          it "sets the new relation on the parent" do
            person.game.should eq(new_game)
          end

          it "removes the old foreign key reference" do
            game.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            game.person.should be_nil
          end

          it "destroys the old child" do
            game.should be_destroyed
          end
        end

        context "when dependent is not set" do

          let!(:account) do
            person.create_account(name: "savings")
          end

          let!(:new_account) do
            Account.create(name: "checking")
          end

          before do
            person.account = new_account
          end

          it "sets the new relation on the parent" do
            person.account.should eq(new_account)
          end

          it "removes the old foreign key reference" do
            account.person_id.should be_nil
          end

          it "removes the reference to the parent" do
            account.person.should be_nil
          end

          it "nullifies the old child" do
            account.should_not be_destroyed
          end
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
          Person.create
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

        it "applies the appropriate dependent option" do
          rating.should_not be_destroyed
        end
      end
    end
  end

  describe "#build_#\{name}" do

    context "when using mass assignment scoping" do

      let(:person) do
        Person.new
      end

      let(:account) do
        person.build_account(
          { name: "bank", balance: "big" }, as: :admin
        )
      end

      it "allows setting of fields for the role" do
        account.name.should eq("bank")
      end

      it "does not set fields not allowed for the role" do
        account.balance.should be_nil
      end
    end

    context "when the relationship is an illegal embedded reference" do

      let(:game) do
        Game.new
      end

      it "raises a mixed relation error" do
        expect {
          game.build_video(title: "Tron")
        }.to raise_error(Mongoid::Errors::MixedRelations)
      end
    end

    context "when the relation is not polymorphic" do

      context "when using object ids" do

        let(:person) do
          Person.create
        end

        let(:game) do
          person.build_game(score: 50)
        end

        it "returns a new document" do
          game.score.should eq(50)
        end

        it "sets the foreign key on the document" do
          game.person_id.should eq(person.id)
        end

        it "sets the inverse relation" do
          game.person.should eq(person)
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
          game.person_id.should eq(person.id)
        end

        it "sets the inverse relation" do
          game.person.should eq(person)
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
          game.person_id.should eq(person.id)
        end

        it "sets the inverse relation" do
          game.person.should eq(person)
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
          bar.build_rating(value: 5)
        end

        it "returns a new document" do
          rating.value.should eq(5)
        end

        it "sets the foreign key on the document" do
          rating.ratable_id.should eq(bar.id)
        end

        it "sets the inverse relation" do
          rating.ratable.should eq(bar)
        end

        it "does not save the built document" do
          rating.should_not be_persisted
        end
      end
    end
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::One
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(extension?: false)
    end

    it "returns the embedded in builder" do
      described_class.builder(nil, metadata, document).should
        be_a_kind_of(builder_klass)
    end
  end

  describe "#create_#\{name}" do

    context "when using mass assignment scoping" do

      let(:person) do
        Person.create
      end

      let(:account) do
        person.create_account(
          { name: "bank", balance: "big" }, as: :admin
        )
      end

      it "allows setting of fields for the role" do
        account.name.should eq("bank")
      end

      it "does not set fields not allowed for the role" do
        account.balance.should be_nil
      end
    end

    context "when the relationship is an illegal embedded reference" do

      let(:game) do
        Game.new
      end

      it "raises a mixed relation error" do
        expect {
          game.create_video(title: "Tron")
        }.to raise_error(Mongoid::Errors::MixedRelations)
      end
    end

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let(:game) do
        person.create_game(score: 50)
      end

      it "returns a new document" do
        game.score.should eq(50)
      end

      it "sets the foreign key on the document" do
        game.person_id.should eq(person.id)
      end

      it "sets the inverse relation" do
        game.person.should eq(person)
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
        game.person_id.should eq(person.id)
      end

      it "sets the inverse relation" do
        game.person.should eq(person)
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
        game.person_id.should eq(person.id)
      end

      it "sets the inverse relation" do
        game.person.should eq(person)
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
        bar.create_rating(value: 5)
      end

      it "returns a new document" do
        rating.value.should eq(5)
      end

      it "sets the foreign key on the document" do
        rating.ratable_id.should eq(bar.id)
      end

      it "sets the inverse relation" do
        rating.ratable.should eq(bar)
      end

      it "saves the document" do
        rating.should be_persisted
      end
    end
  end

  describe ".criteria" do

    let(:id) do
      BSON::ObjectId.new
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        Book.relations["rating"]
      end

      let(:criteria) do
        described_class.criteria(metadata, id, Book)
      end

      it "includes the type in the criteria" do
        criteria.selector.should eq(
          {
            "ratable_id"    => id,
            "ratable_type"  => "Book",
            "ratable_field" => { "$in" => [ :rating, nil ] }
          }
        )
      end
    end

    context "when the relation is not polymorphic" do

      let(:metadata) do
        Person.relations["game"]
      end

      let(:criteria) do
        described_class.criteria(metadata, id, Person)
      end

      it "does not include the type in the criteria" do
        criteria.selector.should eq({ "person_id" => id })
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
        Person.create
      end

      let!(:game) do
        person.create_game(name: "Tron")
      end

      let(:metadata) do
        Person.relations["game"]
      end

      let!(:eager) do
        described_class.eager_load(metadata, Person.all.map(&:_id))
      end

      let(:map) do
        Mongoid::IdentityMap.get(Game, "person_id" => person.id)
      end

      it "puts the documents in the identity map" do
        map.should eq(game)
      end
    end

    context "when the relation is polymorphic" do

      let!(:book) do
        Book.create(name: "Game of Thrones")
      end

      let!(:movie) do
        Movie.create(name: "Bladerunner")
      end

      let!(:movie_rating) do
        movie.ratings.create(value: 10)
      end

      let!(:book_rating) do
        book.create_rating(value: 10)
      end

      let(:metadata) do
        Book.relations["rating"]
      end

      let!(:eager) do
        described_class.eager_load(metadata, Book.all.map(&:_id))
      end

      let(:map) do
        Mongoid::IdentityMap.get(Rating, "ratable_id" => book.id)
      end

      it "puts the documents in the identity map" do
        map.should eq(book_rating)
      end
    end
  end

  describe ".embedded?" do

    it "returns false" do
      described_class.should_not be_embedded
    end
  end

  describe ".foreign_key_suffix" do

    it "returns _id" do
      described_class.foreign_key_suffix.should eq("_id")
    end
  end

  describe ".macro" do

    it "returns has_one" do
      described_class.macro.should eq(:has_one)
    end
  end

  describe "#nullify" do

    let(:person) do
      Person.create
    end

    let!(:game) do
      person.create_game(name: "Starcraft II")
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
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let!(:game) do
      person.build_game(name: "Tron")
    end

    let(:document) do
      person.game
    end

    Mongoid::Document.public_instance_methods(true).each do |method|

      context "when checking #{method}" do

        it "returns true" do
          document.respond_to?(method).should be_true
        end
      end
    end
  end

  describe ".stores_foreign_key?" do

    it "returns false" do
      described_class.stores_foreign_key?.should be_false
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      described_class.valid_options.should eq(
        [ :as, :autobuild, :autosave, :dependent, :foreign_key ]
      )
    end
  end

  describe ".validation_default" do

    it "returns true" do
      described_class.validation_default.should be_true
    end
  end

  context "when reloading the relation" do

    let!(:person) do
      Person.create
    end

    let!(:game_one) do
      Game.create(name: "Warcraft 3")
    end

    let!(:game_two) do
      Game.create(name: "Starcraft 2")
    end

    before do
      person.game = game_one
    end

    context "when the relation references the same document" do

      before do
        Game.collection.find({ _id: game_one.id }).
          update({ "$set" => { name: "Diablo 2" }})
      end

      let(:reloaded) do
        person.game(true)
      end

      it "reloads the document from the database" do
        reloaded.name.should eq("Diablo 2")
      end

      it "sets a new document instance" do
        reloaded.should_not equal(game_one)
      end
    end

    context "when the relation references a different document" do

      before do
        person.game = game_two
      end

      let(:reloaded) do
        person.game(true)
      end

      it "reloads the new document from the database" do
        reloaded.name.should eq("Starcraft 2")
      end

      it "sets a new document instance" do
        reloaded.should_not equal(game_one)
      end
    end
  end
end
