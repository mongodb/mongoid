# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Includable do

  describe "#includes" do

    let!(:person) do
      Person.create!(age: 1)
    end

    context "when providing a name that is not a relation" do

      it "raises an error" do
        expect {
          Person.includes(:members)
        }.to raise_error(Mongoid::Errors::InvalidIncludes)
      end
    end

    context "when providing one association" do

      let!(:user) do
        User.create!(posts: [ post1 ])
      end

      let!(:post1) do
        Post.create!
      end

      let(:result) do
        User.includes(:posts).first
      end

      it "executes the query" do
        expect(result).to eq(user)
      end

      it "includes the related objects" do
        expect(result.posts).to eq([ post1 ])
      end
    end

    context "when providing a list of associations" do

      let!(:user) do
        User.create!(posts: [ post1 ], descriptions: [ description1 ])
      end

      let!(:post1) do
        Post.create!
      end

      let!(:description1) do
        Description.create!(details: 1)
      end

      let(:result) do
        User.includes(:posts, :descriptions).first
      end

      it "executes the query" do
        expect(result).to eq(user)
      end

      it "includes the related objects" do
        expect(result.posts).to eq([ post1 ])
        expect(result.descriptions).to eq([ description1 ])
      end
    end

    context "when providing a nested association" do

      let!(:user) do
        User.create!
      end

      before do
        p = Post.create!(alerts: [ Alert.create! ])
        user.posts = [ p ]
        user.save!
      end

      let(:result) do
        User.includes(:posts => [:alerts]).first
      end

      it "executes the query" do
        expect(result).to eq(user)
      end

      it "includes the related objects" do
        expect(result.posts.size).to eq(1)
        expect(result.posts.first.alerts.size).to eq(1)
      end
    end

    context "when providing a deeply nested association" do

      let!(:user) do
        User.create!
      end

      let(:results) do
        User.includes(:posts => [{ :alerts => :items }]).to_a
      end

      it "executes the query" do
        expect(results.first).to eq(user)
      end
    end

    context "when the models are inherited" do

      before(:all) do
        class A
          include Mongoid::Document
        end

        class B < A
          belongs_to :c
        end

        class C
          include Mongoid::Document
          has_one :b
        end
      end

      after(:all) do
        Object.send(:remove_const, :A)
        Object.send(:remove_const, :B)
        Object.send(:remove_const, :C)
      end

      context "when the includes is on the subclass" do

        let!(:c_one) do
          C.create!
        end

        let!(:c_two) do
          C.create!
        end

        let!(:b) do
          B.create!(c: c_two)
        end

        let!(:results) do
          C.includes(:b).to_a.detect do |c|
            c.id == c_two.id
          end
        end

        it "returns the correct documents" do
          expect(results).to eq(c_two)
        end

        it "does not query the db" do
          expect_query(0) do
            results.b
          end
        end
      end
    end

    context "when the models are inherited from another one model" do

      context "when the relation is a has_one" do

        before(:all) do
          class A
            include Mongoid::Document
          end

          class B < A
            belongs_to :d
          end

          class C < A
            belongs_to :d
          end

          class D
            include Mongoid::Document
            has_one :b
            has_one :c
          end
        end

        after(:all) do
          Object.send(:remove_const, :A)
          Object.send(:remove_const, :B)
          Object.send(:remove_const, :C)
          Object.send(:remove_const, :D)
        end

        context "when the includes is on the several relations" do

          let!(:d_one) do
            D.create!
          end

          let!(:d_two) do
            D.create!
          end

          let!(:b) do
            B.create!(d: d_two)
          end

          let!(:c) do
            C.create!(d: d_two)
          end

          let!(:results) do
            D.includes(:b, :c).entries.detect do |d|
              d.id == d_two.id
            end
          end

          it "returns the correct documents" do
            expect(results).to eq(d_two)
          end

          it "does not query the db on b" do
            expect_query(0) do
              results.b
            end
          end

          it "does not query the db on c" do
            expect_query(0) do
              results.b
            end
          end
        end
      end

      context "when the relation is a has_many" do

        before(:all) do
          class A
            include Mongoid::Document
          end

          class B < A
            belongs_to :d
          end

          class C < A
            belongs_to :d
          end

          class D
            include Mongoid::Document
            has_many :b
            has_many :c
          end
        end

        after(:all) do
          Object.send(:remove_const, :A)
          Object.send(:remove_const, :B)
          Object.send(:remove_const, :C)
          Object.send(:remove_const, :D)
        end

        context "when the includes is on the several relations" do

          let!(:d_one) do
            D.create!
          end

          let!(:d_two) do
            D.create!
          end

          let!(:bs) do
            2.times.map { B.create!(d: d_two) }
          end

          let!(:cs) do
            2.times.map { C.create!(d: d_two) }
          end

          let!(:results) do
            D.includes(:b, :c).entries.detect do |d|
              d.id == d_two.id
            end
          end

          it "returns the correct documents" do
            expect(results).to eq(d_two)
          end

          it "does not query the db on b" do
            expect_query(0) do
              results.b
            end
          end

          it "does not query the db on c" do
            expect_query(0) do
              results.b
            end
          end
        end
      end
    end

    context "when including the same association multiple times" do

      let(:criteria) do
        Person.all.includes(:posts, :posts).includes(:posts)
      end

      let(:association) do
        Person.reflect_on_association(:posts)
      end

      it "does not duplicate the association in the inclusions" do
        expect(criteria.inclusions).to eq([ association ])
      end
    end

    context "when mapping the results more than once" do

      let!(:post) do
        person.posts.create!(title: "one")
      end

      let(:criteria) do
        Post.includes(:person)
      end

      let!(:results) do
        criteria.map { |doc| doc }
        criteria.map { |doc| doc }
      end

      it "returns the proper results" do
        expect(results.first.title).to eq("one")
      end
    end

    context "when including a belongs to relation" do

      context "when the criteria is from the root" do

        let!(:person_two) do
          Person.create!(age: 2)
        end

        let!(:post_one) do
          person.posts.create!(title: "one")
        end

        let!(:post_two) do
          person_two.posts.create!(title: "two")
        end

        context "when calling first" do

          let(:criteria) do
            Post.includes(:person)
          end

          let!(:document) do
            criteria.first
          end

          it "eager loads the first document" do
            expect_query(0) do
              expect(document.person).to eq(person)
            end
          end

          it "returns the first document" do
            expect(document).to eq(post_one)
          end
        end

        context "when calling last" do

          let!(:criteria) do
            Post.asc(:_id).includes(:person)
          end

          let!(:document) do
            criteria.last
          end

          it "eager loads the last document" do
            expect_query(0) do
              expect(document.person).to eq(person_two)
            end
          end

          it "returns the last document" do
            expect(document).to eq(post_two)
          end
        end
      end

      context "when the criteria is from an embedded relation" do

        let(:peep) do
          Person.create!
        end

        let!(:address_one) do
          peep.addresses.create!(street: "rosenthaler")
        end

        let!(:address_two) do
          peep.addresses.create!(street: "weinmeister")
        end

        let!(:depeche) do
          Band.create!(name: "Depeche Mode")
        end

        let!(:tool) do
          Band.create!(name: "Tool")
        end

        before do
          address_one.band = depeche
          address_two.band = tool
          address_one.save!
          address_two.save!
        end

        context "when calling first" do

          let(:criteria) do
            peep.reload.addresses.includes(:band)
          end

          let(:context) do
            criteria.context
          end

          let!(:document) do
            criteria.first
          end

          it "eager loads the first document" do
            expect_query(0) do
              expect(document.band).to eq(depeche)
            end
          end

          it "returns the document" do
            expect(document).to eq(address_one)
          end
        end

        context "when calling last" do

          let(:criteria) do
            peep.reload.addresses.includes(:band)
          end

          let(:context) do
            criteria.context
          end

          let!(:document) do
            criteria.last
          end

          it "eager loads the last document" do
            expect_query(0) do
              expect(document.band).to eq(tool)
            end
          end

          it "returns the document" do
            expect(document).to eq(address_two)
          end
        end

        context "when iterating all documents" do

          let(:criteria) do
            peep.reload.addresses.includes(:band)
          end

          let(:context) do
            criteria.context
          end

          let!(:documents) do
            criteria.to_a
          end

          it "eager loads the first document" do
            expect_query(0) do
              expect(documents.first.band).to eq(depeche)
            end
          end

          it "eager loads the last document" do
            expect_query(0) do
              expect(documents.last.band).to eq(tool)
            end
          end

          it "returns the documents" do
            expect(documents).to eq([ address_one, address_two ])
          end
        end
      end
    end

    context "when providing inclusions to the default scope" do

      before do
        Person.default_scope(->{ Person.includes(:posts) })
      end

      after do
        Person.default_scoping = nil
      end

      let!(:post_one) do
        person.posts.create!(title: "one")
      end

      let!(:post_two) do
        person.posts.create!(title: "two")
      end

      context "when the criteria has no options" do

        let!(:criteria) do
          Person.asc(:age).all
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(documents).to eq([ person ])
        end

        it "eager loads the first document" do
          expect_query(0) do
            expect(documents.first.posts.first).to eq(post_one)
          end
        end

        it "eager loads the last document" do
          expect_query(0) do
            expect(documents.first.posts.last).to eq(post_two)
          end
        end

        context "when executing the query twice" do

          let!(:new_criteria) do
            Person.where(id: person.id)
          end

          let!(:new_context) do
            new_criteria.context
          end

          before do
            expect(new_context).to receive(:eager_load).with([person]).once.and_call_original
          end

          let!(:from_db) do
            new_criteria.first
          end

          it "does not duplicate documents in the relation" do
            expect(person.posts.size).to eq(2)
          end
        end
      end

      context "when calling first on the criteria" do

        let(:criteria) do
          Person.asc(:age).all
        end

        let!(:from_db) do
          criteria.first
        end

        it "returns the correct documents" do
          expect(from_db).to eq(person)
        end

        it "eager loads the first document" do
          expect_query(0) do
            expect(from_db.posts.first).to eq(post_one)
          end
        end

        it "eager loads the last document" do
          expect_query(0) do
            expect(from_db.posts.last).to eq(post_two)
          end
        end
      end

      context "when calling last on the criteria" do

        let(:criteria) do
          Person.asc(:age).all
        end

        let!(:context) do
          criteria.context
        end

        before do
          expect(context).to receive(:eager_load).with([person]).once.and_call_original
        end

        let!(:from_db) do
          criteria.last
        end

        it "returns the correct documents" do
          expect(from_db).to eq(person)
        end

        it "eager loads the first document" do
          expect_query(0) do
            expect(from_db.posts.first).to eq(post_one)
          end
        end

        it "eager loads the last document" do
          expect_query(0) do
            expect(from_db.posts.last).to eq(post_two)
          end
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create!
        end

        let!(:post_three) do
          person_two.posts.create!(title: "three")
        end

        let!(:criteria) do
          Person.asc(:age).limit(1)
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(criteria).to eq([ person ])
        end

        it "eager loads the first document" do
          expect_query(0) do
            expect(documents.first.posts.first).to eq(post_one)
          end
        end

        it "eager loads the second document" do
          expect_query(0) do
            expect(documents.first.posts.last).to eq(post_two)
          end
        end
      end
    end

    context "when including a has and belongs to many" do

      let!(:preference_one) do
        person.preferences.create!(name: "one")
      end

      let!(:preference_two) do
        person.preferences.create!(name: "two")
      end

      context "when one of the related items is deleted" do

        before do
          person.preferences = [ preference_one, preference_two ]
          preference_two.delete
        end

        let(:criteria) do
          Person.where(id: person.id).includes(:preferences)
        end

        it "only loads the existing related items" do
          expect(criteria.entries.first.preferences).to eq([ preference_one ])
        end
      end

      context "when the criteria has no options" do

        let!(:criteria) do
          Person.asc(:age).includes(:preferences)
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(documents).to eq([ person ])
        end

        it "eager loads the first document" do
          expect_query(0) do
            expect(documents.first.preferences.first).to eq(preference_one)
          end
        end

        it "eager loads the last document" do
          expect_query(0) do
            expect(documents.first.preferences.last).to eq(preference_two)
          end
        end
      end

      context "when calling first on the criteria" do

        let!(:criteria) do
          Person.asc(:age).includes(:preferences)
        end

        let!(:from_db) do
          criteria.first
        end

        it "returns the correct documents" do
          expect(from_db).to eq(person)
        end

        it "eager loads the first document" do
          expect_query(0) do
            expect(from_db.preferences.first).to eq(preference_one)
          end
        end

        it "eager loads the last document" do
          expect_query(0) do
            expect(from_db.preferences.last).to eq(preference_two)
          end
        end
      end

      context "when calling last on the criteria" do

        let!(:criteria) do
          Person.asc(:age).includes(:preferences)
        end

        let!(:from_db) do
          criteria.last
        end

        it "returns the correct documents" do
          expect(from_db).to eq(person)
        end

        it "eager loads the first document" do
          expect_query(0) do
            expect(from_db.preferences.first).to eq(preference_one)
          end
        end

        it "eager loads the last document" do
          expect_query(0) do
            expect(from_db.preferences.last).to eq(preference_two)
          end
        end
      end
    end

    context "when including a has many" do

      let!(:post_one) do
        person.posts.create!(title: "one")
      end

      let!(:post_two) do
        person.posts.create!(title: "two")
      end

      context "when the criteria has no options" do

        let!(:criteria) do
          Person.asc(:age).includes(:posts)
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(documents).to eq([ person ])
        end

        it "eager loads the first document" do
          expect_query(0) do
            expect(documents.first.posts.first).to eq(post_one)
          end
        end

        it "eager loads the last document" do
          expect_query(0) do
            expect(documents.first.posts.last).to eq(post_two)
          end
        end
      end

      context "when calling first on the criteria" do

        let!(:criteria) do
          Person.asc(:age).includes(:posts)
        end

        let!(:from_db) do
          criteria.first
        end

        it "returns the correct documents" do
          expect(from_db).to eq(person)
        end

        context "when subsequently getting all documents" do

          let!(:documents) do
            criteria.entries
          end

          it "returns the correct documents" do
            expect(documents).to eq([ person ])
          end
        end
      end

      context "when calling last on the criteria" do

        let!(:criteria) do
          Person.asc(:age).includes(:posts)
        end

        let!(:from_db) do
          criteria.last
        end

        it "returns the correct documents" do
          expect(from_db).to eq(person)
        end

        context "when subsequently getting all documents" do

          let!(:documents) do
            criteria.entries
          end

          it "returns the correct documents" do
            expect(documents).to eq([ person ])
          end
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create!
        end

        let!(:post_three) do
          person_two.posts.create!(title: "three")
        end

        let!(:criteria) do
          Person.includes(:posts).asc(:age).limit(1)
        end

        let(:context) do
          criteria.context
        end

        before do
          expect(context).to receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(documents).to eq([ person ])
        end
      end
    end

    context "when including a has one" do

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person.create_game(name: "two")
      end

      context "when the criteria has no options" do

        let!(:criteria) do
          Person.asc(:age).includes(:game)
        end

        let(:context) do
          criteria.context
        end

        before do
          expect(context).to receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(documents).to eq([ person ])
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create!(age: 2)
        end

        let!(:game_three) do
          person_two.create_game(name: "Skyrim")
        end

        let!(:criteria) do
          Person.where(id: person.id).includes(:game).asc(:age).limit(1)
        end

        let(:context) do
          criteria.context
        end

        before do
          expect(context).to receive(:eager_load).with([ person ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(documents).to eq([ person ])
        end
      end
    end

    context "when including a belongs to" do

      let(:person_two) do
        Person.create!(age: 2)
      end

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person_two.create_game(name: "two")
      end

      context "when providing no options" do

        let!(:criteria) do
          Game.includes(:person)
        end

        let(:context) do
          criteria.context
        end

        before do
          expect(context).to receive(:preload).twice.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(criteria).to eq([ game_one, game_two ])
        end
      end

      context "when the criteria has limiting options" do

        let!(:criteria) do
          Game.where(id: game_one.id).includes(:person).asc(:_id).limit(1)
        end

        let(:context) do
          criteria.context
        end

        before do
          expect(context).to receive(:eager_load).with([ game_one ]).once.and_call_original
        end

        let!(:documents) do
          criteria.entries
        end

        it "returns the correct documents" do
          expect(documents).to eq([ game_one ])
        end
      end
    end

    context "when including multiples in the same criteria" do

      let!(:post_one) do
        person.posts.create!(title: "one")
      end

      let!(:post_two) do
        person.posts.create!(title: "two")
      end

      let!(:game_one) do
        person.create_game(name: "one")
      end

      let!(:game_two) do
        person.create_game(name: "two")
      end

      let!(:criteria) do
        Person.includes(:posts, :game).asc(:age)
      end

      let(:context) do
        criteria.context
      end

      before do
        expect(context).to receive(:preload).twice.and_call_original
      end

      let!(:documents) do
        criteria.entries
      end

      it "returns the correct documents" do
        expect(criteria).to eq([ person ])
      end
    end
  end

  describe "#inclusions" do

    let(:criteria) do
      Band.includes(:records)
    end

    let(:association) do
      Band.relations["records"]
    end

    it "returns the inclusions" do
      expect(criteria.inclusions).to eq([ association ])
    end
  end

  describe "#inclusions=" do

    let(:criteria) do
      Band.all
    end

    let(:association) do
      Band.relations["records"]
    end

    before do
      criteria.inclusions = [ association ]
    end

    it "sets the inclusions" do
      expect(criteria.inclusions).to eq([ association ])
    end
  end
end
