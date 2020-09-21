# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::QueryCache do

  around do |spec|
    Mongoid::QueryCache.clear_cache
    Mongoid::QueryCache.cache { spec.run }
  end

  context 'when iterating over objects sharing the same base' do

    let(:server) do
      relations.first.mongo_client.cluster.next_primary
    end

    before do
      person = Person.create
      3.times do
        person.send(relation).create
      end
      person.save
    end

    let!(:relations) do
      Person.first.send(relation).to_a
    end

    context 'when the association is has-many' do

      let(:relation) do
        :posts
      end

      context 'does not query for the relation and instead sets the base' do

        before do
          Mongoid::QueryCache.enabled = false
        end

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

        before do
          Mongoid::QueryCache.enabled = false
        end

        it 'does not query for access to the base' do
          expect(server).to receive(:context).exactly(0).times.and_call_original
          relations.each do |object|
            object.person
          end
        end
      end

      context 'when query cache is enabled' do

        before do
          Mongoid::QueryCache.enabled = true
        end

        it 'does not query for access to the base' do
          expect(server).to receive(:context).exactly(0).times.and_call_original
          relations.each do |object|
            object.person
          end
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

        before do
          Mongoid::QueryCache.enabled = false
        end

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
        Person.create
      end
    end

    it 'returns all documents' do
      expect(Person.all.to_a.count).to eq(3)
      Person.first
      expect(Person.all.to_a.count).to eq(3)
    end

    context 'with conditions specified' do
      it 'returns all documents' do
        expect(Person.gt(age: 0).to_a.count).to eq(3)
        Person.gt(age: 0).first
        expect(Person.gt(age: 0).to_a.count).to eq(3)
      end
    end

    context 'with order specified' do
      it 'returns all documents' do
        expect(Person.order_by(name: 1).to_a.count).to eq(3)
        Person.order_by(name: 1).first
        expect(Person.order_by(name: 1).to_a.count).to eq(3)
      end
    end
  end

  context "when querying in the same collection" do

    before do
      Band.all.to_a
    end

    context "when query cache is disabled" do

      before do
        Mongoid::QueryCache.enabled = false
      end

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
          # Server versions older than 3.2 also perform a killCursors operation,
          # which causes this test to fail.
          min_server_version '3.2'

          it "queries again" do
            expect_query(1) do
              result = game.ratings.where(:value.gt => 5).limit(2).asc(:id).to_a
              expect(result.length).to eq(2)
              expect(result.map { |r| r['value'] }).to eq([6, 7])
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

    context 'when querying colleciton larger than the batch size' do
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

      around(:each) do |example|
        query_cache_enabled = Mongoid::QueryCache.enabled?
        Mongoid::QueryCache.enabled = true
        example.run
        Mongoid::QueryCache.enabled = query_cache_enabled
      end

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
      Band.create.id
    end

    context 'when query cache is disabled' do

      before do
        Mongoid::QueryCache.enabled = false
      end

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

      it "returns the same count of objects when using #pluck" do
        expect(Band.pluck(:name).length).to eq(99)
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
    before do
      Mongoid::QueryCache.enabled = true
      10.times { Band.create! }

      Band.batch_size(4).all.any?
    end

    it 'does not cache the result' do
      expect(Band.all.map(&:id).size).to eq(10)
    end

    context 'when a batch size smaller than the result set is specified' do
      let(:batch_size) do
        4
      end

      it 'does not cache the result' do
        expect(Band.batch_size(batch_size).all.map(&:id).size).to eq(10)
      end
    end
  end
end
