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

    context "when the relation is cyclic" do

      let(:user) do
        User.new
      end

      let(:role) do
        Role.new
      end

      before do
        user.role = role
      end

      it "does not raise an error" do
        expect(user.role).to eq(role)
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

        let(:metadata) do
          Game.relations["person"]
        end

        before do
          expect(metadata).to receive(:criteria).never
          person.game = game
        end

        it "sets the target of the relation" do
          expect(person.game.target).to eq(game)
        end

        it "sets the foreign key on the relation" do
          expect(game.person_id).to eq(person.id)
        end

        it "sets the base on the inverse relation" do
          expect(game.person).to eq(person)
        end

        it "sets the same instance on the inverse relation" do
          expect(game.person).to eql(person)
        end

        it "does not save the target" do
          expect(game).to_not be_persisted
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
          expect(person.game.target).to eq(game)
        end

        it "sets the foreign key of the relation" do
          expect(game.person_id).to eq(person.id)
        end

        it "sets the base on the inverse relation" do
          expect(game.person).to eq(person)
        end

        it "sets the same instance on the inverse relation" do
          expect(game.person).to eql(person)
        end

        it "saves the target" do
          expect(game).to be_persisted
        end

        context "when reloading the parent" do

          before do
            person.reload
          end

          context "when setting a new document on the relation" do

            before do
              person.game = Game.new
            end

            it "detaches the previous relation" do
              expect {
                game.reload
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end
        end
      end

      context "when relation have a different primary_key" do

        let(:person) do
          Person.create
        end

        let(:cat) do
          Cat.new
        end

        before do
          person.cat = cat
        end

        it "sets the target of the relation" do
          expect(person.cat.target).to eq(cat)
        end

        it "sets the foreign key of the relation" do
          expect(cat.person_id).to eq(person.username)
        end

        it "sets the base on the inverse relation" do
          expect(cat.person).to eq(person)
        end

        it "sets the same instance on the inverse relation" do
          expect(cat.person).to eql(person)
        end

        it "saves the target" do
          expect(cat).to be_persisted
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
          expect(bar.rating.target).to eq(rating)
        end

        it "sets the foreign key on the relation" do
          expect(rating.ratable_id).to eq(bar.id)
        end

        it "sets the base on the inverse relation" do
          expect(rating.ratable).to eq(bar)
        end

        it "sets the same instance on the inverse relation" do
          expect(rating.ratable).to eql(bar)
        end

        it "does not save the target" do
          expect(rating).to_not be_persisted
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
          expect(bar.rating.target).to eq(rating)
        end

        it "sets the foreign key of the relation" do
          expect(rating.ratable_id).to eq(bar.id)
        end

        it "sets the base on the inverse relation" do
          expect(rating.ratable).to eq(bar)
        end

        it "sets the same instance on the inverse relation" do
          expect(rating.ratable).to eql(bar)
        end

        it "saves the target" do
          expect(rating).to be_persisted
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
            expect(person.game).to eq(new_game)
          end

          it "removes the old foreign key reference" do
            expect(game.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(game.person).to be_nil
          end

          it "destroys the old child" do
            expect(game).to be_destroyed
          end

          it "leaves the old child unpersisted" do
            expect(game.persisted?).to be false
          end

          it "leaves the new child persisted" do
            expect(new_game.persisted?).to be true
          end
        end

        context "with a new one built via the parent" do

          let!(:new_game) do
            person.build_game(name: "Starcraft 2")
          end

          it "sets the new relation on the parent" do
            expect(person.game).to eq(new_game)
          end

          it "removes the old foreign key reference" do
            expect(game.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(game.person).to be_nil
          end

          it "does not destroy the old child" do
            expect(game).to_not be_destroyed
          end

          it "leaves the old child persisted" do
            expect(game.persisted?).to be true
          end

          it "leaves the new child unpersisted" do
            expect(new_game.persisted?).to be false
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
            expect(person.game).to eq(new_game)
          end

          it "removes the old foreign key reference" do
            expect(game.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(game.person).to be_nil
          end

          it "destroys the old child" do
            expect(game).to be_destroyed
          end

          it "leaves the old child unpersisted" do
            expect(game.persisted?).to be false
          end

          it "leaves the new child persisted" do
            expect(new_game.persisted?).to be true
          end
        end

        context "with a new one built via the parent" do

          let!(:new_game) do
            person.build_game(name: "Starcraft 2")
          end

          it "sets the new relation on the parent" do
            expect(person.game).to eq(new_game)
          end

          it "removes the old foreign key reference" do
            expect(game.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(game.person).to be_nil
          end

          it "does not destroy the old child" do
            expect(game).to_not be_destroyed
          end

          it "leaves the old child unpersisted" do
            expect(game.persisted?).to be false
          end

          it "leaves the new child unpersisted" do
            expect(new_game.persisted?).to be false
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
            expect(person.cat).to eq(new_cat)
          end

          it "removes the old foreign key reference" do
            expect(cat.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(cat.person).to be_nil
          end

          it "does not destroy the old child" do
            expect(cat).to_not be_destroyed
          end

          it "leaves the old child persisted" do
            expect(cat.persisted?).to be true
          end

          it "leaves the new child persisted" do
            expect(new_cat.persisted?).to be true
          end
        end

        context "with a new one built via the parent" do

          let!(:new_cat) do
            person.build_cat(name: "Brutus")
          end

          it "sets the new relation on the parent" do
            expect(person.cat).to eq(new_cat)
          end

          it "removes the old foreign key reference" do
            expect(cat.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(cat.person).to be_nil
          end

          it "does not destroy the old child" do
            expect(cat).to_not be_destroyed
          end

          it "leaves the old child persisted" do
            expect(cat.persisted?).to be true
          end

          it "leaves the new child unpersisted" do
            expect(new_cat.persisted?).to be false
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
            expect(person.cat).to eq(new_cat)
          end

          it "removes the old foreign key reference" do
            expect(cat.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(cat.person).to be_nil
          end

          it "does not destroy the old child" do
            expect(cat).to_not be_destroyed
          end

          it "leaves the old child unpersisted" do
            expect(cat.persisted?).to be false
          end

          it "leaves the new child persisted" do
            expect(new_cat.persisted?).to be true
          end
        end

        context "with a new one built via the parent" do

          let!(:new_cat) do
            person.build_cat(name: "Brutus")
          end

          it "sets the new relation on the parent" do
            expect(person.cat).to eq(new_cat)
          end

          it "removes the old foreign key reference" do
            expect(cat.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(cat.person).to be_nil
          end

          it "does not destroy the old child" do
            expect(cat).to_not be_destroyed
          end

          it "leaves the old child unpersisted" do
            expect(cat.persisted?).to be false
          end

          it "leaves the new child unpersisted" do
            expect(new_cat.persisted?).to be false
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
            expect(person.game).to eq(new_game)
          end

          it "removes the old foreign key reference" do
            expect(game.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(game.person).to be_nil
          end

          it "destroys the old child" do
            expect(game).to be_destroyed
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
            expect(person.account).to eq(new_account)
          end

          it "removes the old foreign key reference" do
            expect(account.person_id).to be_nil
          end

          it "removes the reference to the parent" do
            expect(account.person).to be_nil
          end

          it "nullifies the old child" do
            expect(account).to_not be_destroyed
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
          expect(person.game).to be_nil
        end

        it "removed the inverse relation" do
          expect(game.person).to be_nil
        end

        it "removes the foreign key value" do
          expect(game.person_id).to be_nil
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
          expect(person.game).to be_nil
        end

        it "removed the inverse relation" do
          expect(game.person).to be_nil
        end

        it "removes the foreign key value" do
          expect(game.person_id).to be_nil
        end

        it "deletes the target from the database" do
          expect(game).to be_destroyed
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
          expect(bar.rating).to be_nil
        end

        it "removed the inverse relation" do
          expect(rating.ratable).to be_nil
        end

        it "removes the foreign key value" do
          expect(rating.ratable_id).to be_nil
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
          expect(bar.rating).to be_nil
        end

        it "removed the inverse relation" do
          expect(rating.ratable).to be_nil
        end

        it "removes the foreign key value" do
          expect(rating.ratable_id).to be_nil
        end

        it "applies the appropriate dependent option" do
          expect(rating).to_not be_destroyed
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
          expect(game.score).to eq(50)
        end

        it "sets the foreign key on the document" do
          expect(game.person_id).to eq(person.id)
        end

        it "sets the inverse relation" do
          expect(game.person).to eq(person)
        end

        it "does not save the built document" do
          expect(game).to_not be_persisted
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
          expect(game.person_id).to eq(person.id)
        end

        it "sets the inverse relation" do
          expect(game.person).to eq(person)
        end

        it "does not save the built document" do
          expect(game).to_not be_persisted
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
          expect(game.person_id).to eq(person.id)
        end

        it "sets the inverse relation" do
          expect(game.person).to eq(person)
        end

        it "does not save the built document" do
          expect(game).to_not be_persisted
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
          expect(rating.value).to eq(5)
        end

        it "sets the foreign key on the document" do
          expect(rating.ratable_id).to eq(bar.id)
        end

        it "sets the inverse relation" do
          expect(rating.ratable).to eq(bar)
        end

        it "does not save the built document" do
          expect(rating).to_not be_persisted
        end
      end
    end
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::One
    end

    let(:document) do
      double
    end

    let(:metadata) do
      double(extension?: false)
    end

    it "returns the embedded in builder" do
      expect(
        described_class.builder(nil, metadata, document)
      ).to be_a_kind_of(builder_klass)
    end
  end

  describe "#create_#\{name}" do

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
        expect(game.score).to eq(50)
      end

      it "sets the foreign key on the document" do
        expect(game.person_id).to eq(person.id)
      end

      it "sets the inverse relation" do
        expect(game.person).to eq(person)
      end

      it "saves the document" do
        expect(game).to be_persisted
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
        expect(game.person_id).to eq(person.id)
      end

      it "sets the inverse relation" do
        expect(game.person).to eq(person)
      end

      it "saves the document" do
        expect(game).to be_persisted
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
        expect(game.person_id).to eq(person.id)
      end

      it "sets the inverse relation" do
        expect(game.person).to eq(person)
      end

      it "saves the document" do
        expect(game).to be_persisted
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
        expect(rating.value).to eq(5)
      end

      it "sets the foreign key on the document" do
        expect(rating.ratable_id).to eq(bar.id)
      end

      it "sets the inverse relation" do
        expect(rating.ratable).to eq(bar)
      end

      it "saves the document" do
        expect(rating).to be_persisted
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
        expect(criteria.selector).to eq(
          {
            "ratable_id"    => id,
            "ratable_type"  => "Book"
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
        expect(criteria.selector).to eq({ "person_id" => id })
      end
    end
  end

  describe ".embedded?" do

    it "returns false" do
      expect(described_class).to_not be_embedded
    end
  end

  describe ".foreign_key_suffix" do

    it "returns _id" do
      expect(described_class.foreign_key_suffix).to eq("_id")
    end
  end

  describe ".macro" do

    it "returns has_one" do
      expect(described_class.macro).to eq(:has_one)
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
        expect(game.person_id).to be_nil
      end

      it "removes the reference from the target" do
        expect(game.person).to be_nil
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
        expect(game_reloaded.person_id).to be_nil
      end

      it "removes the reference from the target" do
        expect(game_reloaded.person).to be_nil
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
          expect(document.respond_to?(method)).to be true
        end
      end
    end
  end

  describe ".stores_foreign_key?" do

    it "returns false" do
      expect(described_class.stores_foreign_key?).to be false
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      expect(described_class.valid_options).to eq(
        [ :as, :autobuild, :autosave, :dependent, :foreign_key, :primary_key ]
      )
    end
  end

  describe ".validation_default" do

    it "returns true" do
      expect(described_class.validation_default).to be true
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
          update_one({ "$set" => { name: "Diablo 2" }})
      end

      let(:reloaded) do
        person.game(true)
      end

      it "reloads the document from the database" do
        expect(reloaded.name).to eq("Diablo 2")
      end

      it "sets a new document instance" do
        expect(reloaded).to_not equal(game_one)
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
        expect(reloaded.name).to eq("Starcraft 2")
      end

      it "sets a new document instance" do
        expect(reloaded).to_not equal(game_one)
      end
    end
  end

  context "when dependent is set to delete for child" do

    context "when autobuild is true for child" do

      let(:explosion) do
        Explosion.create
      end

      let(:bomb) do
        bomb = Bomb.create
        bomb.explosion = explosion
        bomb
      end

      let(:clear_child) do
        bomb.explosion.clear
      end

      it "clearing the child raises no error" do
        expect{ clear_child }.not_to raise_error
      end
    end
  end
end
