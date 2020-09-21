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

      context 'when query cache is disabled' do

        before do
          Mongoid::QueryCache.enabled = false
        end

        it 'queries for each access to the base' do
          expect_query(relations.size) do
            relations.each do |object|
              object.person
            end
          end
        end
      end

      context 'when query cache is enabled' do

        before do
          Mongoid::QueryCache.enabled = true
        end

        it 'queries only once for the base' do
          expect_query(1) do
            relations.each do |object|
              object.person
            end
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

      context 'when the first query has a collation', if: collation_supported? do

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

  context "when querying a very large collection" do

    before do
      100.times { Band.create! }
    end

    it "returns the right number of records" do
      expect(Band.all.to_a.length).to eq(100)
    end

    it "#pluck returns the same count of objects" do
      expect(Band.pluck(:name).length).to eq(100)
    end

    context "when loading all the documents" do

      before do
        Band.all.to_a
      end

      it "caches the complete result of the query" do
        expect_no_queries do
          expect(Band.all.to_a.length).to eq(100)
        end
      end

      it "returns the same count of objects when using #pluck" do
        expect(Band.pluck(:name).length).to eq(100)
      end
    end
  end

  context "when inserting an index" do

    it "does not cache the query" do
      expect(Mongoid::QueryCache).to receive(:cache_table).never
      Band.collection.indexes.create_one(name: 1)
    end
  end
end

describe Mongoid::QueryCache::Middleware do

  let :middleware do
    Mongoid::QueryCache::Middleware.new(app)
  end

  context "when not touching mongoid on the app" do

    let(:app) do
      ->(env) { @enabled = Mongoid::QueryCache.enabled?; [200, env, "app"] }
    end

    it "returns success" do
      code, _ = middleware.call({})
      expect(code).to eq(200)
    end

    it "enableds the query cache" do
      middleware.call({})
      expect(@enabled).to be true
    end
  end

  context "when querying on the app" do

    let(:app) do
      ->(env) {
        Band.all.to_a
        [200, env, "app"]
      }
    end

    it "returns success" do
      code, _ = middleware.call({})
      expect(code).to eq(200)
    end

    it "cleans the query cache after reponds" do
      middleware.call({})
      expect(Mongoid::QueryCache.cache_table).to be_empty
    end
  end
end
