# frozen_string_literal: true

require "spec_helper"
require 'mongoid/association/referenced/has_many_models'

describe Mongoid::QueryCache do

  around do |spec|
    Mongoid::QueryCache.clear_cache
    Mongoid::QueryCache.cache { spec.run }
  end

  before(:all) do
    # It is likely that there are other session leaks in the driver
    # and/or Mongoid that are unrelated to the query cache. Clear the
    # SessionRegistry at the start of these tests in order to detect leaks that
    # occur only within the scope of these tests.
    #
    # Other session leaks will be detected and addressed as part of RUBY-2391.
    Mrss::SessionRegistry.instance.clear_registry
  end

  after do
    Mrss::SessionRegistry.instance.verify_sessions_ended!
  end

  describe '#cache' do

    context 'with driver query cache' do

      context 'when query cache is not enabled' do
        override_query_cache false

        it 'turns on the query cache within the block' do
          expect(Mongoid::QueryCache.enabled?).to be false

          Mongoid::QueryCache.cache do
            expect(Mongoid::QueryCache.enabled?).to be true
          end

          expect(Mongoid::QueryCache.enabled?).to be false
        end
      end

      context 'when query cache is enabled' do
        override_query_cache true

        it 'keeps the query cache enabled within the block' do
          expect(Mongoid::QueryCache.enabled?).to be true

          Mongoid::QueryCache.cache do
            expect(Mongoid::QueryCache.enabled?).to be true
          end

          expect(Mongoid::QueryCache.enabled?).to be true
        end
      end

      context 'nested inside #uncached' do
        it 'turns on the query cache in the block' do
          Mongoid::QueryCache.uncached do
            expect(Mongoid::QueryCache.enabled?).to be false

            Mongoid::QueryCache.cache do
              expect(Mongoid::QueryCache.enabled?).to be true
            end

            expect(Mongoid::QueryCache.enabled?).to be false
          end
        end
      end
    end
  end

  describe '#uncached' do

    context 'with driver query cache' do

      context 'when query cache is not enabled' do
        override_query_cache false

        it 'keeps the query cache turned off within the block' do
          expect(Mongoid::QueryCache.enabled?).to be false

          Mongoid::QueryCache.uncached do
            expect(Mongoid::QueryCache.enabled?).to be false
          end

          expect(Mongoid::QueryCache.enabled?).to be false
        end
      end

      context 'when query cache is enabled' do
        override_query_cache true

        it 'turns off the query cache within the block' do
          expect(Mongoid::QueryCache.enabled?).to be true

          Mongoid::QueryCache.uncached do
            expect(Mongoid::QueryCache.enabled?).to be false
          end

          expect(Mongoid::QueryCache.enabled?).to be true
        end
      end

      context 'nested inside #cache' do
        it 'turns on the query cache in the block' do
          Mongoid::QueryCache.cache do
            expect(Mongoid::QueryCache.enabled?).to be true

            Mongoid::QueryCache.uncached do
              expect(Mongoid::QueryCache.enabled?).to be false
            end

            expect(Mongoid::QueryCache.enabled?).to be true
          end
        end
      end
    end
  end

  context 'when iterating over objects sharing the same base' do

    let(:server) do
      relations.first.mongo_client.cluster.next_primary
    end

    before do
      person = Person.create!
      3.times do
        person.send(relation).create!
      end
      person.save!
    end

    let!(:relations) do
      Person.first.send(relation).to_a
    end

    context 'when the association is has-many' do

      let(:relation) do
        :posts
      end

      context 'does not query for the relation and instead sets the base' do
        override_query_cache false

        it 'queries for each access to the base' do
          expect(server).to receive(:with_connection).exactly(0).times.and_call_original
          relations.each do |object|
            object.person
          end
        end
      end
    end

    context 'when the association is embeds-many' do

      let(:relation) do
        :symptoms
      end

      context 'when query cache is disabled' do
        override_query_cache false

        it 'does not query for access to the base' do
          expect(server).to receive(:context).exactly(0).times.and_call_original
          relations.each do |object|
            object.person
          end
        end
      end

      context 'when query cache is enabled' do
        override_query_cache true

        it 'does not query for access to the base' do
          expect(server).to receive(:context).exactly(0).times.and_call_original
          relations.each do |object|
            object.person
          end
        end
      end
    end
  end

  context 'when driver query cache exists' do

    before do
      Band.all.to_a
      Band.create!
    end

    it 'recognizes the driver query cache' do
      expect(defined?(Mongo::QueryCache)).to_not be_nil
    end

    context 'when query cache enabled' do

      it 'uses the driver query cache' do
        expect(Mongo::QueryCache).to receive(:enabled=).and_call_original
        Mongoid::QueryCache.enabled = true

        expect(Mongoid::QueryCache.enabled?).to be(true)
        expect(Mongo::QueryCache.enabled?).to be(true)
      end
    end

    context 'when query cache disabled' do

      it 'uses the driver query cache' do
        expect(Mongo::QueryCache).to receive(:enabled=).and_call_original
        Mongoid::QueryCache.enabled = false

        expect(Mongoid::QueryCache.enabled?).to be(false)
        expect(Mongo::QueryCache.enabled?).to be(false)
      end
    end

    context 'when block is cached' do
      override_query_cache false

      it 'uses the driver query cache' do
        expect(Mongo::QueryCache).to receive(:cache).and_call_original
        Mongoid::QueryCache.cache do
          expect(Mongo::QueryCache).to receive(:enabled?).exactly(2).and_call_original
          expect(Mongoid::QueryCache.enabled?).to be(true)
          expect(Mongo::QueryCache.enabled?).to be(true)
        end
      end
    end

    context 'when block is uncached' do
      override_query_cache true

      it 'uses the driver query cache' do
        expect(Mongo::QueryCache).to receive(:uncached).and_call_original
        Mongoid::QueryCache.uncached do
          expect(Mongo::QueryCache).to receive(:enabled?).exactly(2).and_call_original
          expect(Mongoid::QueryCache.enabled?).to be(false)
          expect(Mongo::QueryCache.enabled?).to be(false)
        end
      end
    end

    context 'when clear_cache is used' do

      before do
        Band.all.to_a
      end

      it 'requires Mongoid to query again' do
        expect_no_queries do
          Band.all.to_a
        end

        Mongoid::QueryCache.clear_cache

        expect_query(1) do
          Band.all.to_a
        end
      end
    end

    context 'when query cache used and cleared' do
      it 'uses the driver query cache' do
        expect(Mongo::QueryCache).to receive(:set).once.and_call_original

        expect_query(1) do
          Band.all.to_a
          Band.all.to_a
        end
      end
    end
  end

  context "when querying for a single document" do

    [ :first, :one, :last ].each do |method|

      before do
        Band.all.send(method)
      end

      context "when query cache is disabled" do
        override_query_cache false

        it "queries again" do
          expect_query(1) do
            Band.all.send(method)
          end
        end
      end

      context "with same selector" do

        it "does not query again" do
          expect_no_queries do
            Band.all.send(method)
          end
        end
      end

      context "with different selector" do

        it "queries again" do
          expect_query(1) do
            Band.where(id: 1).send(method)
          end
        end
      end
    end
  end

  context 'querying all documents after a single document' do
    before do
      3.times do
        Person.create!
      end
    end

    it 'returns all documents' do
      # Mongoid adds a sort by _id to the Person.first call, which is why
      # these commands issue two queries instead of one.
      expect_query(2) do
        expect(Person.all.to_a.count).to eq(3)
        Person.first
        expect(Person.all.to_a.count).to eq(3)
      end
    end

    it 'caches the query when order is specified' do
      expect_query(1) do
        expect(Person.order(_id: 1).all.to_a.count).to eq(3)
        Person.first
        expect(Person.order(_id: 1).all.to_a.count).to eq(3)
      end
    end

    context 'with conditions specified' do
      it 'returns all documents' do
        # Mongoid adds a sort by _id to the Person.first call, which is why
        # these commands issue two queries instead of one.
        expect_query(2) do
          expect(Person.gt(age: 0).to_a.count).to eq(3)
          Person.gt(age: 0).first
          expect(Person.gt(age: 0).to_a.count).to eq(3)
        end
      end

      it 'caches the query when order is specified' do
        expect_query(1) do
          expect(Person.order(_id: 1).gt(age: 0).to_a.count).to eq(3)
          Person.gt(age: 0).first
          expect(Person.order(_id: 1).gt(age: 0).to_a.count).to eq(3)
        end
      end
    end

    context 'with order specified' do
      it 'returns all documents' do
        expect_query(1) do
          expect(Person.order_by(name: 1).to_a.count).to eq(3)
          Person.order_by(name: 1).first
          expect(Person.order_by(name: 1).to_a.count).to eq(3)
        end
      end
    end
  end

  context 'when using a block API' do
    before do
      Band.destroy_all
      5.times { Band.create! }
    end

    context '#any? with no block' do
      it 'doesn\'t leak sessions' do
        Band.all.any?
      end
    end

    context '#all? with no block' do
      it 'doesn\'t leak sessions' do
        Band.all.all?
      end
    end

    context '#none? with no block' do
      it 'doesn\'t leak sessions' do
        Band.all.none?
      end
    end

    context '#one? with no block' do
      it 'doesn\'t leak sessions' do
        Band.all.one?
      end
    end
  end

  context "when querying in the same collection" do

    before do
      Band.all.to_a
    end

    context "when query cache is disabled" do
      override_query_cache false

      it "queries again" do
        expect_query(1) do
          Band.all.to_a
        end
      end
    end

    context "with same selector" do

      it "does not query again" do
        expect_no_queries do
          Band.all.to_a
        end
      end

      context 'when the first query has a collation' do
        min_server_version '3.4'

        before do
          Band.where(name: 'DEPECHE MODE').collation(locale: 'en_US', strength: 2).to_a
        end

        context "when the next query has the same collation" do

          it "uses the cache" do
            expect_no_queries do
              Band.where(name: 'DEPECHE MODE').collation(locale: 'en_US', strength: 2).to_a
            end
          end
        end

        context "when the next query does not have the same collation" do

          it "queries again" do
            expect_query(1) do
              Band.where(name: 'DEPECHE MODE').collation(locale: 'fr', strength: 2).to_a
            end
          end
        end

        context "when the next query does not have a collation" do

          it "queries again" do
            expect_query(1) do
              Band.where(name: 'DEPECHE MODE').to_a
            end
          end
        end
      end

      context "when the first query has no limit" do

        let(:game) do
          Game.create!(name: "2048")
        end

        before do
          10.times do |i|
            game.ratings << Rating.create!(value: i+1)
          end

          game.ratings.where(:value.gt => 5).asc(:id).all.to_a
        end

        context "when the next query has a limit" do

          it "uses the cache" do
            expect_no_queries do
              result = game.ratings.where(:value.gt => 5).limit(2).asc(:id).to_a
              expect(result.length).to eq(2)
              expect(result.map { |r| r['value'] }).to eq([6, 7])
            end
          end
        end
      end

      context "when the first query has a limit" do
        let(:game) do
          Game.create!(name: "2048")
        end

        before do
          10.times do |i|
            game.ratings << Rating.create!(value: i+1)
          end

          game.ratings.where(:value.gt => 5).limit(3).asc(:id).all.to_a
        end

        context "when the next query has a limit" do

          context 'with driver query cache' do

            # The driver query cache re-uses results with a larger limit
            it 'does not query again' do
              expect_no_queries do
                result = game.ratings.where(:value.gt => 5).limit(2).asc(:id).to_a
                expect(result.length).to eq(2)
                expect(result.map { |r| r['value'] }).to eq([6, 7])
              end
            end
          end
        end

        context "when the new query does not have a limit" do

          it "queries again" do
            expect_query(1) do
              result = game.ratings.where(:value.gt => 5).asc(:id).to_a
              expect(result.length).to eq(5)
              expect(result.map { |r| r['value'] }).to eq([6, 7, 8, 9, 10])
            end
          end
        end
      end

      context "when querying only the first" do

        let(:game) do
          Game.create!(name: "2048")
        end

        before do
          10.times do |i|
            game.ratings << Rating.create!(value: i+1)
          end

          game.ratings.where(:value.gt => 5).asc(:id).all.to_a
        end

        it "does not query again" do
          expect_no_queries do
            result = game.ratings.where(:value.gt => 5).asc(:id).first
            expect(result['value']).to eq(6)
          end
        end
      end

      context "when limiting the result" do
        before do
          Band.destroy_all

          5.times { |i| Band.create!(name: "Band #{i}") }
          Band.all.to_a
        end

        it "does not query again" do
          expect_query(0) do
            result = Band.limit(2).all.to_a
            expect(result.length).to eq(2)
            expect(result.map { |r| r["name"] }).to eq(["Band 0", "Band 1"])
          end
        end
      end

      context "when specifying a different skip value" do

        before do
          Band.destroy_all

          5.times { |i| Band.create!(name: "Band #{i}") }
          Band.limit(2).skip(1).all.to_a
        end

        it "queries again" do
          expect_query(1) do
            result = Band.limit(2).skip(3).all.to_a
            expect(result.length).to eq(2)
            expect(result.map { |r| r["name"] }).to eq(["Band 3", "Band 4"])
          end
        end
      end
    end

    context "with different selector" do

      it "queries again" do
        expect_query(1) do
          Band.where(id: 1).to_a
        end
      end
    end

    context "when sorting documents" do
      before do
        Band.asc(:id).to_a
      end

      context "with different selector" do

        it "queries again" do
          expect_query(1) do
            Band.desc(:id).to_a
          end
        end
      end

      it "does not query again" do
        expect_query(0) do
          Band.asc(:id).to_a
        end
      end
    end

   context 'when querying collection larger than the batch size' do
     before do
       Band.destroy_all
       101.times { |i| Band.create!(_id: i) }
     end

     it 'does not raise an exception when querying multiple times' do
       expect do
         results1 = Band.all.to_a
         expect(results1.length).to eq(101)
         expect(results1.map { |band| band["_id"] }).to eq([*0..100])

         results2 = Band.all.to_a
         expect(results2.length).to eq(101)
         expect(results2.map { |band| band["_id"] }).to eq([*0..100])
       end.not_to raise_error
     end
   end

    context "when query caching is enabled and the batch_size is set" do
      override_query_cache true

      it "does not raise an error when requesting the second batch" do
        expect {
          Band.batch_size(4).where(:views.gte => 0).each do |doc|
            doc.set(likes: Random.rand(100))
          end
        }.not_to raise_error
      end
    end
  end

  context "when querying in different collection" do

    before do
      Person.all.to_a
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end

  context "when inserting a new document" do

    before do
      Band.all.to_a
      Band.create!
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end

  context "when deleting all documents" do

    before do
      Band.create!
      Band.all.to_a
      Band.delete_all
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end

  context "when destroying all documents" do

    before do
      Band.create!
      Band.all.to_a
      Band.destroy_all
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end

  context "when reloading a document" do

    let!(:band_id) do
      Band.create!.id
    end

    context 'when query cache is disabled' do
      override_query_cache false

      it "queries again" do
        band = Band.find(band_id)
        expect_query(1) do
          band.reload
        end
      end
    end

    context 'when query cache is enabled' do

      it "queries again" do
        band = Band.find(band_id)
        expect_query(1) do
          band.reload
        end
      end
    end
  end

  context "when querying collection smaller than the batch size" do

    before do
      99.times { Band.create! }
    end

    it "returns the right number of records" do
      expect(Band.all.to_a.length).to eq(99)
    end

    it "#pluck returns the same count of objects" do
      expect(Band.pluck(:name).length).to eq(99)
    end

    context "when loading all the documents" do

      before do
        Band.all.to_a
      end

      it "caches the complete result of the query" do
        expect_no_queries do
          expect(Band.all.to_a.length).to eq(99)
        end
      end

      it "returns the same count of objects when using #pluck but doesn't cache" do
        expect_query(1) do
          expect(Band.pluck(:name).length).to eq(99)
        end
      end
    end
  end

  context "when inserting an index" do

    it "does not cache the query" do
      expect(Mongoid::QueryCache).to receive(:cache_table).never
      Band.collection.indexes.create_one(name: 1)
    end
  end

  context 'when the initial query does not exhaust the results' do
    override_query_cache true

    before do
      10.times { Band.create! }

      Band.batch_size(4).to_a
    end

    context 'with driver query cache' do

      # The driver query cache caches multi-batch cursors
      it 'does cache the result' do
        expect_no_queries do
          expect(Band.all.map(&:id).size).to eq(10)
        end
      end
    end
  end

  context 'when storing in system collection' do
    it 'does not cache the query' do
      expect_query(2) do
        SystemRole.all.to_a
        SystemRole.all.to_a
      end
    end
  end

  context 'after calling none? on an association' do
    let!(:host) do
      HmmSchool.delete_all
      school = HmmSchool.create!
      5.times do
        HmmStudent.create!(school: school)
      end
    end

    let(:school) { HmmSchool.first }

    before do
      Mongoid::QueryCache.clear_cache

      school.students.none?
    end

    it 'returns all children for the association' do
      school.students.to_a.length.should == 5
    end
  end

  describe 'deprecation warnings' do

    context '#cache' do
      it 'should raise a warning' do
        expect(Mongoid::Warnings).to receive(:warn_mongoid_query_cache)
        Mongoid::QueryCache.cache {}
      end
    end

    context '#uncached' do
      it 'should raise a warning' do
        expect(Mongoid::Warnings).to receive(:warn_mongoid_query_cache)
        Mongoid::QueryCache.uncached {}
      end
    end

    context '#clear_cache' do
      it 'should raise a warning' do
        expect(Mongoid::Warnings).to receive(:warn_mongoid_query_cache_clear)
        Mongoid::QueryCache.clear_cache
      end
    end

    context '#enabled?' do
      it 'should raise a warning' do
        expect(Mongoid::Warnings).to receive(:warn_mongoid_query_cache)
        Mongoid::QueryCache.enabled?
      end
    end

    context '#enabled=' do
      it 'should raise a warning' do
        old_enabled = Mongoid::QueryCache.enabled?
        expect(Mongoid::Warnings).to receive(:warn_mongoid_query_cache)
        Mongoid::QueryCache.enabled = old_enabled
      end
    end
  end
end
