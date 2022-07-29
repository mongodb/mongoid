# frozen_string_literal: true

require "spec_helper"
require_relative '../belongs_to_models.rb'

describe Mongoid::Association::Referenced::BelongsTo::Proxy do

  before(:all) do
    Person.reset_callbacks(:validate)
  end

  let(:person) do
    Person.create!
  end

  describe "#=" do

    context "when the relation is named target" do

      let(:target) do
        User.new
      end

      context "when the relation is referenced from an embeds many" do

        context "when setting via create" do

          let(:service) do
            person.services.create(target: target)
          end

          it "sets the target relation" do
            expect(service.target).to eq(target)
          end
        end
      end
    end

    context "when the inverse relation has no reference defined" do

      let(:agent) do
        Agent.new(title: "007")
      end

      let(:game) do
        Game.new(name: "Donkey Kong")
      end

      before do
        agent.game = game
      end

      it "sets the relation" do
        expect(agent.game).to eq(game)
      end

      it "sets the foreign_key" do
        expect(agent.game_id).to eq(game.id)
      end
    end

    context "when referencing a document from an embedded document" do

      let(:person) do
        Person.create!
      end

      let(:address) do
        person.addresses.create!(street: "Wienerstr")
      end

      let(:account) do
        Account.create!(name: "1", number: 1000000)
      end

      before do
        address.account = account
      end

      it "sets the relation" do
        expect(address.account).to eq(account)
      end

      it "does not erase the association metadata" do
        expect(address._association).to_not be_nil
      end

      it "allows saving of the embedded document" do
        expect(address.save!).to be true
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
            expect(game.person._target).to eq(person)
          end

          it "sets the foreign key on the relation" do
            expect(game.person_id).to eq(person.id)
          end

          it "sets the base on the inverse relation" do
            expect(person.game).to eq(game)
          end

          it "sets the same instance on the inverse relation" do
            expect(person.game).to eql(game)
          end

          it "does not save the target" do
            expect(person).to_not be_persisted
          end

          it "drops private visibility from private methods" do
            # This is unfortunate but it appears that Ruby does not
            # have a way to distinguish how method_missing was invoked
            # (i.e. via an explicit send or method call).
            # See https://jira.mongodb.org/browse/MONGOID-5009
            game.person.secret_name.should == 'secret'
          end

          it "allows private methods to be invoked" do
            game.person.send(:secret_name).should == 'secret'
          end

          it "properly exposes delegated methods visibility" do
            expect(defined?(game.person.id)).to eq("method")
            expect(defined?(game.person.secret_name)).to be_nil
          end
        end

        context "when the child is not a new record" do

          let(:person) do
            Person.new
          end

          let(:game) do
            Game.create!
          end

          before do
            game.person = person
          end

          it "sets the target of the relation" do
            expect(game.person._target).to eq(person)
          end

          it "sets the foreign key of the relation" do
            expect(game.person_id).to eq(person.id)
          end

          it "sets the base on the inverse relation" do
            expect(person.game).to eq(game)
          end

          it "sets the same instance on the inverse relation" do
            expect(person.game).to eql(game)
          end

          it "does not saves the target" do
            expect(person).to_not be_persisted
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when the parent is a subclass" do

          let(:canvas) do
            Canvas::Test.create!
          end

          let(:comment) do
            Comment.create!(title: "test")
          end

          before do
            comment.commentable = canvas
            comment.save!
          end

          it "sets the correct value in the type field" do
            expect(comment.commentable_type).to eq("Canvas::Test")
          end

          it "can retrieve the document from the database" do
            expect(comment.reload.commentable).to eq(canvas)
          end
        end

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
            expect(rating.ratable._target).to eq(bar)
          end

          it "sets the foreign key on the relation" do
            expect(rating.ratable_id).to eq(bar.id)
          end

          it "sets the base on the inverse relation" do
            expect(bar.rating).to eq(rating)
          end

          it "sets the same instance on the inverse relation" do
            expect(bar.rating).to eql(rating)
          end

          it "does not save the target" do
            expect(bar).to_not be_persisted
          end
        end

        context "when the child is not a new record" do

          let(:bar) do
            Bar.new
          end

          let(:rating) do
            Rating.create!
          end

          before do
            rating.ratable = bar
          end

          it "sets the target of the relation" do
            expect(rating.ratable._target).to eq(bar)
          end

          it "sets the foreign key of the relation" do
            expect(rating.ratable_id).to eq(bar.id)
          end

          it "sets the base on the inverse relation" do
            expect(bar.rating).to eq(rating)
          end

          it "sets the same instance on the inverse relation" do
            expect(bar.rating).to eql(rating)
          end

          it "does not saves the target" do
            expect(bar).to_not be_persisted
          end
        end
      end
    end

    context "when the parent is a references many" do

      context "when the relation is not polymorphic" do

        context 'when the child has persistence options set' do

          before do
            Person.collection.client['other-posts'].delete_many
            Person.collection.client['other-people'].delete_many
          end

          let(:person) do
            Person.new
          end

          let(:post) do
            Post.new
          end

          before do
            post.with(collection: 'other-posts') do |post|
              person.with(collection: 'other-people') do |person|
                post.person = person
                person.save!
                post.save!
              end
            end
          end

          let(:other_people_count) do
            Person.with(collection: 'other-people') do |person_class|
              person_class.count
            end
          end

          let(:other_posts_count) do
            Post.with(collection: 'other-posts') do |post_class|
              post_class.count
            end
          end

          it 'applies the persistence options when saving the child' do
            expect(other_people_count).to eq(1)
            expect(other_posts_count).to eq(1)
          end
        end

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
            expect(post.person._target).to eq(person)
          end

          it "sets the foreign key on the relation" do
            expect(post.person_id).to eq(person.id)
          end

          it "does not save the target" do
            expect(person).to_not be_persisted
          end
        end

        context "when the child is not a new record" do

          let(:person) do
            Person.new
          end

          let(:post) do
            Post.create!
          end

          before do
            post.person = person
          end

          it "sets the target of the relation" do
            expect(post.person._target).to eq(person)
          end

          it "sets the foreign key of the relation" do
            expect(post.person_id).to eq(person.id)
          end

          it "does not saves the target" do
            expect(person).to_not be_persisted
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when multiple relations against the same class exist" do

          let(:face) do
            Face.new
          end

          let(:eye) do
            Eye.new
          end

          it "raises an error" do
            expect {
              eye.eyeable = face
            }.to raise_error(Mongoid::Errors::InvalidSetPolymorphicRelation)
          end
        end

        context "when multiple relations of the same name but different class exist" do

          let(:eye) do
            Eye.new
          end

          let(:eye_bowl) do
            EyeBowl.new
          end

          it "should assign as expected" do
            eye.suspended_in = eye_bowl
            expect(eye.suspended_in._target).to eq(eye_bowl)
          end
        end

        context "when one relation against the same class exists" do

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
              expect(rating.ratable._target).to eq(movie)
            end

            it "sets the foreign key on the relation" do
              expect(rating.ratable_id).to eq(movie.id)
            end

            it "does not save the target" do
              expect(movie).to_not be_persisted
            end
          end

          context "when the child is not a new record" do

            let(:movie) do
              Movie.new
            end

            let(:rating) do
              Rating.create!
            end

            before do
              rating.ratable = movie
            end

            it "sets the target of the relation" do
              expect(rating.ratable._target).to eq(movie)
            end

            it "sets the foreign key of the relation" do
              expect(rating.ratable_id).to eq(movie.id)
            end

            it "does not saves the target" do
              expect(movie).to_not be_persisted
            end
          end
        end
      end
    end
  end

  describe "#= nil" do

    context "when dependent is destroy" do

      let(:account) do
        Account.create!(name: 'checkings')
      end

      let(:drug) do
        Drug.create!
      end

      let(:person) do
        Person.create!
      end

      context "when relation is has_one" do

        around(:each) do |example|
          original_account_dependents = Account.dependents
          Account.dependents = []
          example.run
          Account.dependents = original_account_dependents
        end

        before do
          Account.belongs_to :person, dependent: :destroy
          Person.has_one :account
          person.account = account
          person.save!
        end

        after :all do
          Account.belongs_to :person, dependent: :nullify
          Person.has_one :account, validate: false
        end

        context "when parent exists" do

          context "when child touch the parent" do

            let!(:account_from_db) { account.reload }

            it "queries only the parent" do
              expect_query(1) do
                expect(account_from_db.person.id).to eq(person.id)
              end
            end
          end

          context "when child is destroyed" do

            before do
              account.destroy
            end

            it "deletes child" do
              expect(account).to be_destroyed
            end

            it "deletes parent" do
              expect(person).to be_destroyed
            end
          end
        end
      end

      context "when relation is has_many" do

        around(:each) do |example|
          original_drug_dependents = Drug.dependents
          Drug.dependents = []
          example.run
          Drug.dependents = original_drug_dependents
        end

        before do
          Drug.belongs_to :person, dependent: :destroy
          Person.has_many :drugs
          person.drugs = [drug]
          person.save!
        end

        after :all do
          Drug.belongs_to :person, dependent: :nullify
          Person.has_many :drugs, validate: false
        end

        context "when parent exists" do

          context "when child is destroyed" do

            before do
              drug.destroy
            end

            it "deletes child" do
              expect(drug).to be_destroyed
            end

            it "deletes parent" do
              expect(person).to be_destroyed
            end
          end
        end
      end
    end

    context "when dependent is delete" do

      let(:account) do
        Account.create!(name: 'Foobar')
      end

      let(:drug) do
        Drug.create!
      end

      let(:person) do
        Person.create!
      end

      context "when relation is has_one" do

        around(:each) do |example|
          original_account_dependents = Account.dependents
          Account.dependents = []
          example.run
          Account.dependents = original_account_dependents
        end

        before do
          Account.belongs_to :person, dependent: :delete_all
          Person.has_one :account
          person.account = account
          person.save!
        end

        after :all do
          Account.belongs_to :person, dependent: :nullify
          Person.has_one :account, validate: false
        end

        context "when parent is persisted" do

          context "when child is destroyed" do

            before do
              account.destroy
            end

            it "deletes child" do
              expect(account).to be_destroyed
            end

            it "deletes parent" do
              expect(person).to be_destroyed
            end
          end
        end
      end

      context "when relation is has_many" do

        around(:each) do |example|
          original_drug_dependents = Drug.dependents
          Drug.dependents = []
          example.run
          Drug.dependents = original_drug_dependents
        end

        before do
          Drug.belongs_to :person, dependent: :delete_all
          Person.has_many :drugs
          person.drugs = [drug]
          person.save!
        end

        after :all do
          Drug.belongs_to :person, dependent: :nullify
          Person.has_many :drugs, validate: false
        end

        context "when parent exists" do

          context "when child is destroyed" do

            before do
              drug.destroy
            end

            it "deletes child" do
              expect(drug).to be_destroyed
            end

            it "deletes parent" do
              expect(person).to be_destroyed
            end
          end
        end
      end
    end

    context "when dependent is nullify" do

      let(:account) do
        Account.create!(name: 'Foobar')
      end

      let(:drug) do
        Drug.create!
      end

      let(:person) do
        Person.create!
      end

      context "when relation is has_one" do

        around(:each) do |example|
          original_account_dependents = Account.dependents
          Account.dependents = []
          example.run
          Account.dependents = original_account_dependents
        end

        before do
          Account.belongs_to :person, dependent: :nullify
          Person.has_one :account
          person.account = account
          person.save!
        end

        context "when parent is persisted" do

          context "when child is destroyed" do

            before do
              account.destroy
            end

            it "deletes child" do
              expect(account).to be_destroyed
            end

            it "doesn't delete parent" do
              expect(person).to_not be_destroyed
            end

            it "removes the link" do
              expect(person.account).to be_nil
            end
          end
        end
      end

      context "when relation is has_many" do

        around(:each) do |example|
          original_drug_dependents = Drug.dependents
          Drug.dependents = []
          example.run
          Drug.dependents = original_drug_dependents
        end

        before do
          Drug.belongs_to :person, dependent: :nullify
          Person.has_many :drugs
          person.drugs = [drug]
          person.save!
        end

        context "when parent exists" do

          context "when child is destroyed" do

            before do
              drug.destroy
            end

            it "deletes child" do
              expect(drug).to be_destroyed
            end

            it "doesn't deletes parent" do
              expect(person).to_not be_destroyed
            end

            it "removes the link" do
              expect(person.drugs).to eq([])
            end
          end
        end
      end
    end

    context "when the inverse relation has no reference defined" do

      let(:agent) do
        Agent.new(title: "007")
      end

      let(:game) do
        Game.new(name: "Donkey Kong")
      end

      before do
        agent.game = game
        agent.game = nil
      end

      it "removes the relation" do
        expect(agent.game).to be_nil
      end

      it "removes the foreign_key" do
        expect(agent.game_id).to be_nil
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
            expect(game.person).to be_nil
          end

          it "removed the inverse relation" do
            expect(person.game).to be_nil
          end

          it "removes the foreign key value" do
            expect(game.person_id).to be_nil
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.create!
          end

          let(:game) do
            Game.create!
          end

          before do
            game.person = person
            game.person = nil
          end

          it "sets the relation to nil" do
            expect(game.person).to be_nil
          end

          it "removed the inverse relation" do
            expect(person.game).to be_nil
          end

          it "removes the foreign key value" do
            expect(game.person_id).to be_nil
          end

          it "does not delete the child" do
            expect(game).to_not be_destroyed
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when one relation against the same class exists" do

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
              expect(rating.ratable).to be_nil
            end

            it "removed the inverse relation" do
              expect(bar.rating).to be_nil
            end

            it "removes the foreign key value" do
              expect(rating.ratable_id).to be_nil
            end
          end

          context "when the parent is not a new record" do

            let(:bar) do
              Bar.new
            end

            let(:rating) do
              Rating.create!
            end

            before do
              rating.ratable = bar
              rating.ratable = nil
            end

            it "sets the relation to nil" do
              expect(rating.ratable).to be_nil
            end

            it "removed the inverse relation" do
              expect(bar.rating).to be_nil
            end

            it "removes the foreign key value" do
              expect(rating.ratable_id).to be_nil
            end
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
            expect(post.person).to be_nil
          end

          it "removed the inverse relation" do
            expect(person.posts).to be_empty
          end

          it "removes the foreign key value" do
            expect(post.person_id).to be_nil
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.new
          end

          let(:post) do
            Post.create!
          end

          before do
            post.person = person
            post.person = nil
          end

          it "sets the relation to nil" do
            expect(post.person).to be_nil
          end

          it "removed the inverse relation" do
            expect(person.posts).to be_empty
          end

          it "removes the foreign key value" do
            expect(post.person_id).to be_nil
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
            expect(rating.ratable).to be_nil
          end

          it "removed the inverse relation" do
            expect(movie.ratings).to be_empty
          end

          it "removes the foreign key value" do
            expect(rating.ratable_id).to be_nil
          end
        end

        context "when the parent is not a new record" do

          let(:movie) do
            Movie.new
          end

          let(:rating) do
            Rating.create!
          end

          before do
            rating.ratable = movie
            rating.ratable = nil
          end

          it "sets the relation to nil" do
            expect(rating.ratable).to be_nil
          end

          it "removed the inverse relation" do
            expect(movie.ratings).to be_empty
          end

          it "removes the foreign key value" do
            expect(rating.ratable_id).to be_nil
          end
        end
      end
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let(:game) do
      person.build_game(name: "Tron")
    end

    let(:document) do
      game.person
    end

    Mongoid::Document.public_instance_methods(true).each do |method|

      context "when checking #{method}" do

        it "returns true" do
          expect(document.respond_to?(method)).to be true
        end
      end
    end
  end

  context "when the relation is self referencing" do

    let(:game_one) do
      Game.new(name: "Diablo")
    end

    let(:game_two) do
      Game.new(name: "Warcraft")
    end

    context "when setting the parent" do

      before do
        game_one.parent = game_two
      end

      it "sets the parent" do
        expect(game_one.parent).to eq(game_two)
      end

      it "does not set the parent recursively" do
        expect(game_two.parent).to be_nil
      end
    end
  end

  context "when the relation belongs to a has many and has one" do

    before(:all) do
      class A
        include Mongoid::Document
        has_many :bs, inverse_of: :a
      end

      class B
        include Mongoid::Document
        belongs_to :a, inverse_of: :bs
        belongs_to :c, inverse_of: :b
      end

      class C
        include Mongoid::Document
        has_one :b, inverse_of: :c
      end
    end

    after(:all) do
      Object.send(:remove_const, :A)
      Object.send(:remove_const, :B)
      Object.send(:remove_const, :C)
    end

    context "when setting the has one" do

      let(:a) do
        A.new
      end

      let(:b) do
        B.new
      end

      let(:c) do
        C.new
      end

      before do
        b.c = c
      end

      context "when subsequently setting the has many" do

        before do
          b.a = a
        end

        context "when setting the has one again" do

          before do
            b.c = c
          end

          it "allows the reset of the has one" do
            expect(b.c).to eq(c)
          end
        end
      end
    end
  end

  context "when replacing the relation with another" do

    let!(:person) do
      Person.create!
    end

    let!(:post) do
      Post.create!(title: "test")
    end

    let!(:game) do
      person.create_game(name: "Tron")
    end

    before do
      post.person = game.person
      post.save!
    end

    it "clones the relation" do
      expect(post.person).to eq(person)
    end

    it "sets the foreign key" do
      expect(post.person_id).to eq(person.id)
    end

    it "does not remove the previous relation" do
      expect(game.person).to eq(person)
    end

    it "does not remove the previous foreign key" do
      expect(game.person_id).to eq(person.id)
    end

    context "when reloading" do

      before do
        post.reload
        game.reload
      end

      it "persists the relation" do
        expect(post.reload.person).to eq(person)
      end

      it "persists the foreign key" do
        expect(post.reload.person_id).to eq(game.person_id)
      end

      it "does not remove the previous relation" do
        expect(game.person).to eq(person)
      end

      it "does not remove the previous foreign key" do
        expect(game.person_id).to eq(person.id)
      end
    end
  end

  context "when the document belongs to a has one and has many" do

    let(:movie) do
      Movie.create!(name: "Infernal Affairs")
    end

    let(:account) do
      Account.create!(name: "Leung")
    end

    context "when creating the document" do

      let(:comment) do
        Comment.create!(title: 'My Title', movie: movie, account: account)
      end

      it "sets the correct has one" do
        expect(comment.account).to eq(account)
      end

      it "sets the correct has many" do
        expect(comment.movie).to eq(movie)
      end
    end
  end

  context "when reloading the relation" do

    let!(:person_one) do
      Person.create!
    end

    let!(:person_two) do
      Person.create!(title: "Sir")
    end

    let!(:game) do
      Game.create!(name: "Starcraft 2")
    end

    before do
      game.person = person_one
      game.save!
    end

    context "when the relation references the same document" do

      before do
        Person.collection.find({ _id: person_one.id }).
            update_one({ "$set" => { title: "Madam" }})
      end

      let(:reloaded) do
        game.person(true)
      end

      it "reloads the document from the database" do
        expect(reloaded.title).to eq("Madam")
      end

      it "sets a new document instance" do
        expect(reloaded).to_not equal(person_one)
      end
    end

    context "when the relation references a different document" do

      before do
        game.person_id = person_two.id
        game.save!
      end

      let(:reloaded) do
        game.person(true)
      end

      it "reloads the new document from the database" do
        expect(reloaded.title).to eq("Sir")
      end

      it "sets a new document instance" do
        expect(reloaded).to_not equal(person_one)
      end
    end
  end

  context "when creating with a reference to an integer id parent" do

    let!(:jar) do
      Jar.create! do |doc|
        doc._id = 1
      end
    end

    let(:cookie) do
      Cookie.create!(jar_id: "1")
    end

    it "allows strings to be passed as the id" do
      expect(cookie.jar).to eq(jar)
    end

    it "persists the relation" do
      expect(cookie.reload.jar).to eq(jar)
    end
  end

  context "when setting the relation via the foreign key" do

    context "when the relation exists" do

      let!(:person_one) do
        Person.create!
      end

      let!(:person_two) do
        Person.create!
      end

      let!(:game) do
        Game.create!(person: person_one)
      end

      before do
        game.person_id = person_two.id
      end

      it "sets the new document on the relation" do
        expect(game.person).to eq(person_two)
      end
    end
  end

  describe "#method_missing" do
      let!(:person) do
        Person.create!
      end

      let!(:game) do
        Game.create!(person: person)
      end

    it 'handles keyword args' do
      expect do
        game.person.set_personal_data(ssn: '123', age: 25)
      end.not_to raise_error
    end
  end

  # This is a very specific case, see MONGOID-5089 for more details.
  context "when required is false, child is an orphan, and parent has explicit _id" do
    let(:comment) { BTMComment.create! }
    let(:article) do
      BTMArticle.new(
        comment_ids: [comment.id],
        id: 1
      )
    end

    it "uses the correct explicit id" do
      expect(article.comments.first.article_id).to eq(1)
    end
  end
end
