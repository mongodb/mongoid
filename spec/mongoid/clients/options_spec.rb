# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Clients::Options, retry: 3 do

  before do
    # This test asserts on numbers of open connections,
    # to make these assertions work in jruby we cannot have connections
    # bleeding from one test to another and this includes background SDAM
    # threads in the driver
    Mongoid.disconnect_clients
    Mongoid::Clients.clients.clear
  end

  describe '#with' do

    context 'when passing some options' do

      let(:persistence_context) do
        Minim.with(options) do |klass|
          klass.persistence_context
        end
      end

      let(:options) { { database: 'other' } }

      it 'sets the options on the client' do
        expect(persistence_context.client.options['database']).to eq(options[:database])
      end

      it 'does not set the options on class level' do
        expect(Minim.persistence_context.client.options['database']).to eq('mongoid_test')
      end

      context 'when the options are not valid mongo client options' do

        let(:persistence_context) do
          Minim.with(invalid_options) do |klass|
            klass.persistence_context
          end
        end

        let(:invalid_options) { { bad: 'option' } }

        it 'raises an error' do
          expect {
            persistence_context
          }.to raise_exception(Mongoid::Errors::InvalidPersistenceOption)
        end

        it 'clears the persistence context' do
          begin; persistence_context; rescue Mongoid::Errors::InvalidPersistenceOption; end
          expect(Minim.persistence_context).to eq(Mongoid::PersistenceContext.new(Minim))
        end
      end

      context 'when the options include a collection' do

        let(:options) { { collection: 'another-collection' } }

        it 'uses the collection' do
          expect(persistence_context.collection_name).to eq(options[:collection].to_sym)
          expect(persistence_context.collection.name).to eq(options[:collection])
        end

        it 'does not raise an error' do
          expect(persistence_context.client).to be_a(Mongo::Client)
        end

        it 'does not include the collection option in the client options' do
          expect(persistence_context.client.options[:collection]).to be_nil
          expect(persistence_context.client.options['collection']).to be_nil
        end
      end

      context 'when passing a block' do

        let!(:connections_before) do
          Minim.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:connections_and_cluster_during) do
          connections = nil
          cluster = nil
          Minim.with(options) do |klass|
            klass.where(name: 'emily').to_a
            connections = Minim.mongo_client.database.command(serverStatus: 1).first['connections']['current']
            cluster = Minim.collection.cluster
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
          Minim.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:cluster_before) do
          Minim.persistence_context.cluster
        end

        let(:cluster_after) do
          Minim.persistence_context.cluster
        end

        context 'when the options create a new cluster' do
          # This test fails on sharded topologies in Evergreen but not locally
          require_topology :single, :replica_set

          let(:options) do
            { connect_timeout: 2 }
          end

          it 'creates a new cluster' do
            expect(connections_before).to be <(connections_during)
            expect(cluster_before).not_to be(cluster_during)
          end

          it 'disconnects the new cluster when the block exits' do
            expect(cluster_after).not_to be(cluster_during)

            cluster_during.connected?.should be false
            cluster_before.connected?.should be true
          end
        end

        context 'when the options do not create a new cluster' do
          # This test fails on sharded topologies in Evergreen but not locally
          require_topology :single, :replica_set

          let(:options) do
            { database: 'same-cluster' }
          end

          it 'does not create a new cluster' do
            expect(connections_during).to eq(connections_before)

            cluster_during.should be cluster_before
          end

          it 'does not disconnect the original cluster' do
            expect(cluster_before).to be(cluster_after)

            cluster_before.connected?.should be true
          end
        end

        context 'when the client options were configured using a uri' do

          let(:config) do
            {
                default: { hosts: SpecConfig.instance.addresses, database: database_id },
                analytics: { uri: "mongodb://#{SpecConfig.instance.addresses.first}/analytics-db?connectTimeoutMS=3000" }
            }
          end

          before do
            Mongoid::Config.send(:clients=, config)
          end

          after do
            persistence_context.client.close
          end

          let(:persistence_context) do
            Minim.with(client: :analytics) do |klass|
              klass.persistence_context
            end
          end

          it 'uses the database specified in the uri' do
            expect(persistence_context.database_name).to eq('analytics-db')
            expect(persistence_context.client.database.name).to eq('analytics-db')
          end

          it 'uses the options specified in the uri' do
            expect(persistence_context.client.options[:connect_timeout]).to eq(3)
          end
        end
      end

      context 'when changing the collection' do

        let(:options) do
          { collection: 'other' }
        end

        it 'uses that collection' do
          expect(persistence_context.collection.name).to eq(options[:collection])
        end
      end

      context 'when returning a criteria' do

        shared_context 'applies secondary read preference' do

          let(:context_and_criteria) do
            collection = nil
            cxt = Minim.with(read_secondary_option) do |klass|
              collection = klass.all.collection
              klass.persistence_context
            end
            [ cxt, collection ]
          end

          let(:persistence_context) do
            context_and_criteria[0]
          end

          let(:client) do
            context_and_criteria[1].client
          end

          it 'applies the options to the criteria client' do
            expect(client.options['read']).to eq('mode' => :secondary)
          end
        end

        context 'read: :secondary shorthand' do
          let(:read_secondary_option) { {read: :secondary} }

          it_behaves_like 'applies secondary read preference'
        end

        context 'read: {mode: :secondary}' do
          let(:read_secondary_option) { {read: {mode: :secondary}} }

          it_behaves_like 'applies secondary read preference'
        end
      end

      context 'when the object is shared between threads' do

        before do
          threads = []
          100.times do |i|
            threads << Thread.new do
              if i % 2 == 0
                NameOnly.with(collection: 'British') do |klass|
                  klass.create!(name: 'realised')
                end
              else
                NameOnly.with(collection: 'American') do |klass|
                  klass.create!(name: 'realized')
                end
              end
            end
          end
          threads.collect { |t| t.value }
        end

        let(:british_count) do
          NameOnly.with(collection: 'British') do |klass|
            klass.all.count
          end
        end

        let(:american_count) do
          NameOnly.with(collection: 'American') do |klass|
            klass.all.count
          end
        end

        it "does not share the persistence options" do
          expect(british_count).to eq(50)
          expect(american_count).to eq(50)
        end
      end
    end

    context 'when passing a persistence context' do

      let(:instance) do
        Minim.new
      end

      let(:persistence_context) do
        instance.with(options) do |inst|
          inst.persistence_context
        end
      end

      let(:options) { { database: 'other' } }

      it 'sets the persistence context on the object' do
        Minim.new.with(persistence_context) do |model_instance|
          expect(model_instance.persistence_context.options).to eq(persistence_context.options)
        end
      end
    end
  end

  describe '.with' do

    context 'when passing some options' do

      let(:options) do
        { database: 'other' }
      end

      let(:test_model) do
        Minim.create!
      end

      let(:persistence_context) do
        test_model.with(options) do |object|
          object.persistence_context
        end
      end

      it 'sets the options on the client' do
        expect(persistence_context.client.options['database']).to eq(options[:database])
      end

      it 'does not set the options on instance level' do
        expect(test_model.persistence_context.client.database.name).to eq('mongoid_test')
      end

      context 'when the options are not valid mongo client options' do

        let(:persistence_context) do
          test_model.with(invalid_options) do |object|
            object.persistence_context
          end
        end

        let(:invalid_options) { { bad: 'option' } }

        it 'raises an error' do
          expect {
            persistence_context
          }.to raise_exception(Mongoid::Errors::InvalidPersistenceOption)
        end

        it 'clears the persistence context' do
          begin; persistence_context; rescue Mongoid::Errors::InvalidPersistenceOption; end
          expect(test_model.persistence_context).to eq(Mongoid::PersistenceContext.new(test_model))
        end
      end

      context 'when the client options were configured using a uri' do

        let(:config) do
          {
              default: { hosts: SpecConfig.instance.addresses, database: database_id },
              analytics: {
                uri: "mongodb://#{SpecConfig.instance.addresses.first}/analytics-db",
                options: {
                  server_selection_timeout: 0.5,
                },
              }
          }
        end

        before do
          Mongoid::Config.send(:clients=, config)
        end

        let(:persistence_context) do
          test_model.with(client: :analytics) do |object|
            object.persistence_context
          end
        end

        it 'uses the database specified in the uri' do
          expect(persistence_context.database_name).to eq('analytics-db')
          expect(persistence_context.client.database.name).to eq('analytics-db')
        end
      end

      context 'when passing a block' do

        let!(:connections_before) do
          test_model.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:connections_and_cluster_during) do
          connections = nil
          cluster = test_model.with(options) do |b|
            b.reload
            connections = test_model.mongo_client.database.command(serverStatus: 1).first['connections']['current']
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
          test_model.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:cluster_before) do
          test_model.persistence_context.cluster
        end

        let(:cluster_after) do
          test_model.persistence_context.cluster
        end

        context 'when the options create a new cluster' do
          retry_test
          # This test fails on sharded topologies in Evergreen but not locally
          require_topology :single, :replica_set

          let(:options) do
            { connect_timeout: 2 }
          end

          it 'creates a new cluster' do
            expect(connections_during).to be > connections_before
            expect(cluster_during).not_to be(cluster_before)
          end

          it 'disconnects the new cluster when the block exits' do
            expect(connections_after).to eq(connections_before)
          end
        end

        context 'when the options do not create a new cluster' do
          # This test fails on sharded topologies in Evergreen but not locally
          require_topology :single, :replica_set

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
          expect(persistence_context.collection.name).to eq(options[:collection])
        end
      end

      context 'when the object is shared between threads' do

        before do
          threads = []
          100.times do |i|
            test_model = NameOnly.create!
            threads << Thread.new do
              if i % 2 == 0
                test_model.with(collection: 'British') do |b|
                  b.name = 'realised'
                  b.upsert
                end
              else
                test_model.with(collection: 'American') do |b|
                  b.name = 'realized'
                  b.upsert
                end
              end
            end
          end
          threads.collect { |t| t.value }
        end

        let(:british_count) do
          NameOnly.with(collection: 'British') do |klass|
            klass.all.count
          end
        end

        let(:american_count) do
          NameOnly.with(collection: 'British') do |klass|
            klass.all.count
          end
        end

        it 'does not share the persistence options' do
          expect(british_count).to eq(50)
          expect(american_count).to eq(50)
        end
      end
    end

    context 'when passing a persistence context' do

      let(:persistence_context) do
        Minim.with(options) do |klass|
          klass.persistence_context
        end
      end

      let(:options) { { database: 'other' } }

      it 'sets the persistence context on the object' do
        Minim.with(persistence_context) do |test_model_class|
          expect(test_model_class.persistence_context.options).to eq(persistence_context.options)
        end
      end
    end
  end
end
