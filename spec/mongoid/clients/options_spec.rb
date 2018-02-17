require "spec_helper"

describe Mongoid::Clients::Options do

  before(:all) do
    class TestModel
      include Mongoid::Document
      field :name
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestModel)
  end

  describe '#with', if: non_legacy_server? do

    context 'when passing some options' do

      let(:persistence_context) do
        TestModel.with(options) do |klass|
          klass.persistence_context
        end
      end

      let(:options) { { database: 'other' } }

      it 'sets the options on the client' do
        expect(persistence_context.client.options['database']).to eq(options[:database])
      end

      it 'does not set the options on class level' do
        expect(TestModel.persistence_context.client.options['database']).to eq('mongoid_test')
      end

      context 'when the options are not valid mongo client options' do

        let(:persistence_context) do
          TestModel.with(invalid_options) do |klass|
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
          expect(TestModel.persistence_context).to eq(Mongoid::PersistenceContext.new(TestModel))
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

      context 'when passing a block', if: testing_locally? do

        let!(:connections_before) do
          TestModel.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:connections_and_cluster_during) do
          connections = nil
          cluster = TestModel.with(options) do |klass|
            klass.where(name: 'emily').to_a
            connections = TestModel.mongo_client.database.command(serverStatus: 1).first['connections']['current']
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
          TestModel.mongo_client.database.command(serverStatus: 1).first['connections']['current']
        end

        let!(:cluster_before) do
          TestModel.persistence_context.cluster
        end

        let(:cluster_after) do
          TestModel.persistence_context.cluster
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

        context 'when the client options were configured using a uri' do

          let(:config) do
            {
                default: { hosts: [ "127.0.0.1:27017" ], database: database_id },
                secondary: { uri: "mongodb://127.0.0.1:27017/secondary-db?connectTimeoutMS=3000" }
            }
          end

          before do
            Mongoid::Config.send(:clients=, config)
          end

          after do
            persistence_context.client.close
          end

          let(:persistence_context) do
            TestModel.with(client: :secondary) do |klass|
              klass.persistence_context
            end
          end

          it 'uses the database specified in the uri' do
            expect(persistence_context.database_name).to eq('secondary-db')
            expect(persistence_context.client.database.name).to eq('secondary-db')
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

        let(:context_and_criteria) do
          collection = nil
          cxt = TestModel.with(read: :secondary) do |klass|
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
          expect(client.options['read']).to eq(:secondary)
        end
      end

      context 'when the object is shared between threads' do

        before do
          threads = []
          100.times do |i|
            threads << Thread.new do
              if i % 2 == 0
                TestModel.with(collection: 'British') do |klass|
                  klass.create(name: 'realised')
                end
              else
                TestModel.with(collection: 'American') do |klass|
                  klass.create(name: 'realized')
                end
              end
            end
          end
          threads.collect { |t| t.value }
        end

        let(:british_count) do
          TestModel.with(collection: 'British') do |klass|
            klass.all.count
          end
        end

        let(:american_count) do
          TestModel.with(collection: 'American') do |klass|
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
        TestModel.new
      end

      let(:persistence_context) do
        instance.with(options) do |inst|
          inst.persistence_context
        end
      end

      let(:options) { { database: 'other' } }

      it 'sets the persistence context on the object' do
        TestModel.new.with(persistence_context) do |model_instance|
          expect(model_instance.persistence_context.options).to eq(persistence_context.options)
        end
      end
    end
  end

  describe '.with', if: non_legacy_server? do

    context 'when passing some options' do

      let(:options) do
        { database: 'other' }
      end

      let(:test_model) do
        TestModel.create
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
              default: { hosts: [ "127.0.0.1:27017" ], database: database_id },
              secondary: { uri: "mongodb://127.0.0.1:27017/secondary-db" }
          }
        end

        before do
          Mongoid::Config.send(:clients=, config)
        end

        let(:persistence_context) do
          test_model.with(client: :secondary) do |object|
            object.persistence_context
          end
        end

        it 'uses the database specified in the uri' do
          expect(persistence_context.database_name).to eq('secondary-db')
          expect(persistence_context.client.database.name).to eq('secondary-db')
        end
      end

      context 'when passing a block', if: testing_locally? do

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
          expect(persistence_context.collection.name).to eq(options[:collection])
        end
      end

      context 'when the object is shared between threads' do

        before do
          threads = []
          100.times do |i|
            test_model = TestModel.create
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
          TestModel.with(collection: 'British') do |klass|
            klass.all.count
          end
        end

        let(:american_count) do
          TestModel.with(collection: 'British') do |klass|
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
        TestModel.with(options) do |klass|
          klass.persistence_context
        end
      end

      let(:options) { { database: 'other' } }

      it 'sets the persistence context on the object' do
        TestModel.with(persistence_context) do |test_model_class|
          expect(test_model_class.persistence_context.options).to eq(persistence_context.options)
        end
      end
    end
  end
end
