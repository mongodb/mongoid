# frozen_string_literal: true

require "spec_helper"
require_relative "./includable_spec_models.rb"

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

    context "when including nested referenced associations" do

      context "when using a has_one association" do
        before(:all) do
          class A
            include Mongoid::Document
            has_one :b
          end

          class B
            include Mongoid::Document
            belongs_to :a
            has_one :c
          end

          class C
            include Mongoid::Document
            belongs_to :b
            has_one :d
          end

          class D
            include Mongoid::Document
            belongs_to :c
          end
        end

        after(:all) do
          Object.send(:remove_const, :A)
          Object.send(:remove_const, :B)
          Object.send(:remove_const, :C)
          Object.send(:remove_const, :D)
        end

        let!(:a) do
          A.create!
        end

        let!(:b) do
          B.create!
        end

        let!(:c) do
          C.create!
        end

        let!(:d) do
          D.create!
        end

        before do
          c.d = d
          b.c = c
          a.b = b
        end

        context "when including the belongs_to assocation" do
          let!(:result) do
            C.includes(b: :a).first
          end

          it "finds the right document" do
            expect(result).to eq(c)
            expect(result.b).to eq(c.b)
            expect(result.b.a).to eq(c.b.a)
          end

          it "does not execute a query" do
            expect_no_queries do
              result.b.a
            end
          end
        end

        context "when including a doubly-nested belongs_to assocation" do
          let!(:result) do
            D.includes(c: { b: :a }).first
          end

          it "finds the right document" do
            expect(result).to eq(d)
            expect(result.c).to eq(d.c)
            expect(result.c.b).to eq(d.c.b)
            expect(result.c.b.a).to eq(d.c.b.a)
          end

          it "does not execute a query" do
            expect_no_queries do
              result.c.b.a
            end
          end
        end

        context "when including the has_many assocation" do
          let!(:result) do
            A.includes(b: :c).first
          end

          it "finds the right document" do
            expect(result).to eq(a)
            expect(result.b).to eq(a.b)
            expect(result.b.c).to eq(a.b.c)
          end

          it "does not executes a query" do
            expect_no_queries do
              result.b.c
            end
          end
        end

        context "when including a doubly-nested has_many assocation" do
          let!(:result) do
            A.includes(b: { c: :d }).first
          end

          it "finds the right document" do
            expect(result).to eq(a)
            expect(result.b).to eq(a.b)
            expect(result.b.c).to eq(a.b.c)
            expect(result.b.c.d).to eq(a.b.c.d)
          end

          it "does not execute a query" do
            expect_no_queries do
              result.b.c.d
            end
          end
        end

        context "when there are multiple documents" do
          let!(:as) do
            res = 9.times.map do |i|
              A.create!.tap do |a|
                a.b = B.create!.tap do |b|
                  b.c = C.create!
                end
              end
            end
            [a, *res]
          end

          let!(:results) do
            A.includes(b: :c).entries.sort
          end

          it "finds the right document" do
            as.length.times do |i|
              expect(as[i]).to eq(results[i])
              expect(as[i].b).to eq(results[i].b)
              expect(as[i].b.c).to eq(results[i].b.c)
            end
          end

          it "does not execute a query" do
            expect_no_queries do
              results.each do |a|
                a.b.c
              end
            end
          end
        end

        context "when there are multiple associations" do
          before(:all) do
            class A
              has_one :c
            end

            class C
              belongs_to :a
            end
          end

          let(:c2) { C.create! }
          let(:d2) { D.create! }

          before do
            a.c = c2
            a.c.d = d2
          end

          let!(:results) do
            A.includes(b: { c: :d }, c: :d).first
          end

          it "finds the right document" do
            expect(results).to eq(a)
            expect(results.b).to eq(a.b)
            expect(results.b.c).to eq(a.b.c)
            expect(results.b.c.d).to eq(a.b.c.d)
            expect(results.c).to eq(a.c)
            expect(results.c.d).to eq(a.c.d)
          end

          it "does not execute a query" do
            expect_no_queries do
              results.c.d
              results.b.c.d
            end
          end
        end
      end
    end

    context "when using a has_many association" do

      let!(:user) do
        IncUser.create!(posts: posts, comments: user_comments)
      end

      let!(:posts) do
        [ IncPost.create!(comments: post_comments) ]
      end

      let!(:user_comments) do
        2.times.map{ IncComment.create! }
      end

      let!(:post_comments) do
        2.times.map{ IncComment.create! }
      end

      context "when including the same class twice" do
        let!(:results) do
          IncPost.includes({ user: :comments }, :comments).entries.sort
        end

        it "finds the right documents" do
          posts.length.times do |i|
            expect(posts[i]).to eq(results[i])
            expect(posts[i].user).to eq(results[i].user)
            expect(posts[i].user.comments).to eq(results[i].user.comments)
            expect(posts[i].comments).to eq(results[i].comments)
          end
        end

        it "does not execute a query" do
          expect_no_queries do
            results.each do |res|
              res.user
              res.user.comments.to_a
              res.comments.to_a
            end
          end
        end
      end

      context "when the association chain has a class name twice" do
        let!(:thread) { IncThread.create!(comments: user_comments) }

        let!(:result) do
          IncThread.includes(comments: { user: { posts: :comments } }).first
        end

        it "finds the right document" do
          expect(result).to eq(thread)
          result.comments.length.times do |i|
            c1 = result.comments[i]
            c2 = thread.comments[i]
            expect(c1).to eq(c2)
            expect(c1.user).to eq(c2.user)
            c1.user.posts.length.times do |i|
              p1 = c1.user.posts[i]
              p2 = c2.user.posts[i]

              expect(p1).to eq(p2)
              expect(p1.comments).to eq(p2.comments)
            end
          end
        end

        it "does not execute a query" do
          expect_no_queries do
            result.comments.each do |comment|
              comment.user.posts.each do |post|
                post.comments.to_a
              end
            end
          end
        end
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

  context "When multiple associations reference the same class" do
    before do
      IncBlog.create(
        posts: [
          IncBlogPost.create(author: IncAuthor.create),
          IncBlogPost.create(author: IncAuthor.create),
          IncBlogPost.create(author: IncAuthor.create),
        ],
        highlighted_post: IncBlogPost.create(author: IncAuthor.create)
      )
    end

    let!(:result) do
      IncBlog.includes(:posts, highlighted_post: :author).first
    end

    it "does not execute a query" do
      expect_no_queries do
        result.posts.to_a
        result.highlighted_post
      end
    end

    it "executes a query for the non-retrieved elements" do
      expect_query(3) do
        result.posts.each do |post|
          post.author
        end
      end
    end
  end

  context "When multiple parent_inclusions for the same association" do
    before do
      IncBlog.create(
        posts: [
          IncBlogPost.create(author: IncAuthor.create),
          IncBlogPost.create(author: IncAuthor.create),
          IncBlogPost.create(author: IncAuthor.create),
        ],
        highlighted_post: IncBlogPost.create(author: IncAuthor.create),
        pinned_post: IncBlogPost.create(author: IncAuthor.create)
      )
    end

    let!(:result) do
      IncBlog.includes(:posts, highlighted_post: :author, pinned_post: :author).first
    end

    it "does not execute a query" do
      expect_no_queries do
        result.posts.to_a
        result.highlighted_post
        result.pinned_post
      end
    end

    it "executes a query for the non-retrieved elements" do
      expect_query(3) do
        result.posts.each do |post|
          post.author
        end
      end
    end

    context "when including an association and using each twice on a criteria" do

      let(:criteria) { IncPost.all.includes(:person) }

      before do
        p = IncPerson.create!(name: "name")
        4.times { IncPost.create!(person: p)}
        criteria
        expect_query(2) do
          criteria.each(&:person)
        end
      end

      # The reason we are checking for two operations here is:
      #   - The first operation gets all of the posts
      #   - The second operation gets the person from the first post
      # Now, all subsequent posts should use the eager loaded person when
      # trying to retrieve their person.
      # MONGOID-3942 reported that after iterating the criteria a second time,
      # the posts would not get the eager loaded person.
      it "eager loads the criteria" do
        expect_query(2) do
          criteria.each(&:person)
        end
      end
    end
  end
end
