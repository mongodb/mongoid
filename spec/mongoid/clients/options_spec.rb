require "spec_helper"

describe Mongoid::Clients::Options do

  describe '#with', if: non_legacy_server? do

    context 'when passing some options' do

      let(:options) { { database: 'other' } }

      let(:context) do
        Band.with(options) do |klass|
          klass.persistence_context
        end
      end

      it 'sets the options on the client' do
        expect(context.client.options['database']).to eq(options[:database])
      end

      it 'doesnt set the options on class level' do
        expect(Band.persistence_context.client.options['database']).to eq('mongoid_test')
      end

      context 'when passing a block', if: testing_locally? do

        let!(:connections_before) do
          Band.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:connections_and_cluster_during) do
          connections = nil
          cluster = Band.with(options) do |klass|
            klass.where(name: 'emily').to_a
            connections = Band.mongo_client.database.command(serverStatus: 1).first['connections']['current']
          end
          [ connections, cluster ]
        end

        let(:connections_during) do
          connections_and_cluster_during[0]
        end

        let(:cluster_during) do
          connections_and_cluster_during[1]
        end

        let(:connections_after) do
          Band.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:cluster_before) do
          Band.persistence_context.cluster
        end

        let(:cluster_after) do
          Band.persistence_context.cluster
        end

        context 'when the options create a new cluster' do

          let(:options) do
            { connect_timeout: 2 }
          end

          it 'creates a new cluster' do
            expect(connections_before).to be <(connections_during)
            expect(cluster_before).not_to be(cluster_during)
          end

          it 'disconnects the new cluster when the block exits' do
            expect(connections_before).to eq(connections_after)
          end
        end

        context 'when the options do not create a new cluster' do

          let(:options) do
            { database: 'same-cluster' }
          end

          it 'does not create a new cluster' do
            expect(connections_during).to eq(connections_before)
          end

          it 'does not disconnect the original cluster' do
            expect(connections_after).to eq(connections_before)
            expect(cluster_before).to be(cluster_after)
          end
        end
      end

      context 'when changing the collection' do

        let(:options) do
          { collection: 'other' }
        end

        it 'uses that collection' do
          expect(context.collection.name).to eq(options[:collection])
        end
      end

      context 'when returning a criteria' do

        let(:context_and_criteria) do
          collection = nil
          cxt = Band.with(read: :secondary) do |klass|
            collection = klass.all.collection
            klass.persistence_context
          end
          [ cxt, collection ]
        end

        let(:context) do
          context_and_criteria[0]
        end

        let(:client) do
          context_and_criteria[1].client
        end

        it 'applies the options to the criteria client' do
          expect(client.options['read']).to eq(:secondary)
        end
      end

      context 'when the object is shared between threads' do

        before do
          threads = []
          100.times do |i|
            threads << Thread.new do
              if i % 2 == 0
                Band.with(collection: 'British') do |klass|
                  klass.create(name: 'realised')
                end
              else
                Band.with(collection: 'American') do |klass|
                  klass.create(name: 'realized')
                end
              end
            end
          end
          threads.collect { |t| t.value }
        end

        let(:british_count) do
          Band.with(collection: 'British') do |klass|
            klass.all.count
          end
        end

        let(:american_count) do
          Band.with(collection: 'American') do |klass|
            klass.all.count
          end
        end

        it "does not share the persistence options" do
          expect(british_count).to eq(50)
          expect(american_count).to eq(50)
        end
      end
    end
  end

  describe ".with", if: non_legacy_server? do

    context "when passing some options" do

      let(:options) do
        { database: 'other' }
      end

      let(:band) do
        Band.create
      end

      let(:context) do
        band.with(options) do |klass|
          klass.persistence_context
        end
      end

      it 'sets the options on the client' do
        expect(context.client.options['database']).to eq(options[:database])
      end

      it 'does not set the options on instance level' do
        expect(band.persistence_context.client.database.name).to eq('mongoid_test')
      end

      context 'when passing a block', if: testing_locally? do

        let!(:connections_before) do
          band.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:connections_and_cluster_during) do
          connections = nil
          cluster = band.with(options) do |b|
            b.reload
            connections = band.mongo_client.database.command(serverStatus: 1).first['connections']['current']
            b.persistence_context.cluster
          end
          [ connections, cluster ]
        end

        let(:connections_during) do
          connections_and_cluster_during[0]
        end

        let(:cluster_during) do
          connections_and_cluster_during[1]
        end

        let(:connections_after) do
          band.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:cluster_before) do
          band.persistence_context.cluster
        end

        let(:cluster_after) do
          band.persistence_context.cluster
        end

        context 'when the options create a new cluster' do

          let(:options) do
            { connect_timeout: 2 }
          end

          it 'creates a new cluster' do
            expect(connections_before).to be <(connections_during)
            expect(cluster_before).not_to be(cluster_during)
          end

          it 'disconnects the new cluster when the block exits' do
            expect(connections_before).to eq(connections_after)
          end
        end

        context 'when the options do not create a new cluster' do

          let(:options) { { read: :secondary } }

          it 'does not create a new cluster' do
            expect(connections_during).to eq(connections_before)
          end

          it 'does not disconnect the original cluster' do
            expect(connections_after).to eq(connections_before)
            expect(cluster_before).to be(cluster_after)
          end
        end
      end

      context 'when changing the collection' do

        let(:options) do
          { collection: 'other' }
        end

        it 'uses that collection' do
          expect(context.collection.name).to eq(options[:collection])
        end
      end

      context 'when the object is shared between threads' do

        before do
          threads = []
          100.times do |i|
            band = Band.create
            threads << Thread.new do
              if i % 2 == 0
                band.with(collection: 'British') do |b|
                  b.name = "realised"
                  b.upsert
                end
              else
                band.with(collection: 'American') do |b|
                  b.name = "realized"
                  b.upsert
                end
              end
            end
          end
          threads.collect { |t| t.value }
        end

        let(:british_count) do
          Band.with(collection: 'British') do |klass|
            klass.all.count
          end
        end

        let(:american_count) do
          Band.with(collection: 'British') do |klass|
            klass.all.count
          end
        end

        it "does not share the persistence options" do
          expect(british_count).to eq(50)
          expect(american_count).to eq(50)
        end
      end
    end
  end
end
