# frozen_string_literal: true

require "spec_helper"

describe Mongoid::PersistenceContext do

  let(:persistence_context) do
    described_class.new(object, options)
  end

  let(:object) do
    Band
  end

  describe '.set' do

    let(:options) do
      { collection: :other }
    end

    context 'when the persistence context is set on the thread' do

      let!(:persistence_context) do
        described_class.set(object, options)
      end

      it 'sets the persistence context for the object on the current thread' do
        expect(described_class.get(object)).to be(persistence_context)
        expect(described_class.get(object)).not_to be(nil)
        expect(described_class.get(object).collection.name).to eq('other')
      end

      it 'only sets persistence context for the object on the current thread' do
         Thread.new do
          expect(described_class.get(object)).not_to be(persistence_context)
          expect(described_class.get(object)).to be(nil)
        end.value
      end
    end
  end

  describe '.get' do

    let(:options) do
      { collection: :other }
    end

    context 'when there has been a persistence context set on the current thread' do

      let!(:persistence_context) do
        described_class.set(object, options)
      end

      it 'gets the persistence context for the object on the current thread' do
        expect(described_class.get(object)).to be(persistence_context)
        expect(described_class.get(object).collection.name).to eq('other')
      end

      it 'does not get persistence context for the object from another thread' do
        Thread.new do
          expect(described_class.get(object)).not_to be(persistence_context)
          expect(described_class.get(object)).to be(nil)
        end.value
      end
    end
  end

  describe '.clear' do

    let(:options) do
      { collection: :other }
    end

    context 'when the method throws an error' do

      let!(:persistence_context) do
        described_class.set(object, options).tap do |cxt|
          allow(cxt).to receive(:client).and_raise(Mongoid::Errors::NoClientConfig.new('default'))
        end
      end

      it 'clears the context anyway' do
        begin; described_class.clear(object); rescue; end
        expect(described_class.get(object)).to be(nil)
      end
    end

    context 'when there has been a persistence context set on the current thread' do

      let!(:persistence_context) do
        described_class.set(object, options)
      end

      context 'when no cluster is passed to the method' do

        before do
          described_class.clear(object)
        end

        it 'clears the persistence context for the object on the current thread' do
          expect(described_class.get(object)).to be(nil)
        end
      end

      context 'when a cluster is passed to the method' do

        context 'when the cluster is the same as that of the persistence context on the current thread' do

          let(:client) do
            persistence_context.client
          end

          before do
            described_class.clear(object, client.cluster)
          end

          it 'does not close the cluster' do
            expect(client).not_to receive(:close)
            described_class.clear(object, client.cluster.dup)
          end
        end

        context 'when the cluster is not the same as that of the persistence context on the current thread' do

          let!(:client) do
            persistence_context.client
          end

          it 'closes the client' do
            expect(client).to receive(:close).and_call_original
            described_class.clear(object, client.cluster.dup)
          end
        end
      end
    end

    context 'with reusable client' do
      let(:options) do
        {client: :some_client}
      end

      let(:cluster) do
        double(Mongo::Cluster)
      end

      let(:client) do
        double(Mongo::Client).tap do |client|
          allow(client).to receive(:cluster).and_return(cluster)
        end
      end

      before do
        expect(Mongoid::Clients).to receive(:with_name).with(:some_client).and_return(client)
        expect(client).not_to receive(:close)
      end

      it 'does not close the client' do
        described_class.set(object, options)
        described_class.clear(object, cluster.dup)
      end
    end
  end

  describe '#initialize' do

    let(:options) do
      { collection: 'other' }
    end

    context 'when an object is passed' do

      context 'when the object is a klass' do

        it 'sets the object on the persistence context' do
          expect(persistence_context.instance_variable_get(:@object)).to eq(object)
        end
      end

      context 'when the object is a model instance' do

        let(:object) do
          Band.new
        end

        it 'sets the object on the persistence context' do
          expect(persistence_context.instance_variable_get(:@object)).to eq(object)
        end
      end
    end

    context 'when options are passed' do

      let(:options) do
        { connect_timeout: 3 }
      end

      context 'when the options are valid client options' do

        it 'sets the options on the persistence context object' do
          expect(persistence_context.options).to eq(options)
        end
      end

      context 'when the options are not valid client options' do

        context 'when the options are valid extra options' do

          let(:options) do
            { collection: 'other' }
          end

          it 'sets the options on the persistence context object' do
            expect(persistence_context.collection_name).to eq(options[:collection].to_sym)
          end
        end

        context 'when the options are not valid extra options' do

          let(:options) do
            { invalid: 'option' }
          end

          it 'raises an InvalidPersistenceOption error' do
            expect {
              persistence_context
            }.to raise_error(Mongoid::Errors::InvalidPersistenceOption)
          end
        end
      end
    end
  end

  describe '#collection' do

    let(:persistence_context) do
      described_class.new(object, options)
    end

    let(:options) do
      { read: { 'mode' => :secondary } }
    end

    context 'when a parent object is passed' do

      it 'uses the collection of the parent object' do
        expect(persistence_context.collection(Person.new).name).to eq('people')
      end

      it 'does not memoize the collection' do
        persistence_context.collection
        expect(persistence_context.collection(Person.new).name).to eq('people')
      end

      it 'keeps the other options of the persistence context' do
        expect(persistence_context.collection(Person.new).options[:read]).to eq(options[:read])
      end

      context 'when the parent object has a client set' do

        let(:file) do
          File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
        end

        before do
          Mongoid::Clients.clear
          Mongoid.load!(file, :test)
          Person.store_in(client: 'reports')
        end

        after do
          Person.reset_storage_options!
        end

        it 'uses the client of the parent object' do
          expect(persistence_context.collection(Person.new).client.database.name).to eq('reports')
        end
      end
    end

    context 'when a parent object is not passed' do

      it 'uses the collection of the object' do
        expect(persistence_context.collection.name).to eq('bands')
      end

      it 'does not memoize the collection' do
        persistence_context.collection(Person.new)
        expect(persistence_context.collection.name).to eq('bands')
      end

      it 'keeps the other options of the persistence context' do
        expect(persistence_context.collection.client.options[:read]).to eq(options[:read])
      end
    end
  end

  describe '#collection_name' do

    let(:persistence_context) do
      described_class.new(object, options)
    end

    let(:options) do
      { collection: 'other' }
    end

    context 'when storage options are set on the object' do

      context 'when there are no options passed to the Persistence Context' do

        let(:options) do
          { }
        end

        after do
          object.reset_storage_options!
        end

        context 'when the storage options is static' do

          before do
            object.store_in collection: :schmands
          end

          it 'uses the storage options' do
            expect(persistence_context.collection_name).to eq(:schmands)
          end
        end

        context 'when the storage options is a block' do

          before do
            object.store_in collection: ->{ :schmands }
          end

          it 'uses the storage options' do
            expect(persistence_context.collection_name).to eq(:schmands)
          end
        end
      end

      context 'when there are options passed to the Persistence Context' do

        let(:options) do
          { collection: 'other' }
        end

        after do
          object.reset_storage_options!
        end

        context 'when the storage options is static' do

          before do
            object.store_in collection: :schmands
          end

          it 'uses the persistence context options' do
            expect(persistence_context.collection_name).to eq(:other)
          end
        end

        context 'when the storage options is a block' do

          before do
            object.store_in collection: ->{ :schmands }
          end

          it 'uses the persistence context options' do
            expect(persistence_context.collection_name).to eq(:other)
          end
        end
      end
    end

    context 'when storage options are not set on the object' do

      context 'when there are options passed to the Persistence Context' do

        let(:options) do
          { collection: 'other' }
        end

        it 'uses the persistence context options' do
          expect(persistence_context.collection_name).to eq(:other)
        end
      end
    end
  end

  describe '#database_name' do

    let(:persistence_context) do
      described_class.new(object, options)
    end

    let(:options) do
      { database: 'other' }
    end

    context 'when storage options are set on the object' do

      context 'when there are no options passed to the Persistence Context' do

        let(:options) do
          { }
        end

        after do
          object.reset_storage_options!
        end

        context 'when there is a database override' do
          persistence_context_override :database, :other

          before do
            object.store_in database: :musique
          end

          it 'uses the override' do
            expect(persistence_context.database_name).to eq(:other)
          end
        end

        context 'when the storage options is static' do

          before do
            object.store_in database: :musique
          end

          it 'uses the storage options' do
            expect(persistence_context.database_name).to eq(:musique)
          end
        end

        context 'when the storage options is a block' do

          before do
            object.store_in database: ->{ :musique }
          end
          it 'uses the storage options' do
            expect(persistence_context.database_name).to eq(:musique)
          end
        end
      end

      context 'when there are options passed to the Persistence Context' do

        let(:options) do
          { database: 'musique' }
        end

        context 'when there is a database override' do
          persistence_context_override :database, :other

          it 'uses the persistence context options' do
            expect(persistence_context.database_name).to eq(:musique)
          end
        end

        context 'when the storage options is static' do

          before do
            object.store_in database: :sounds
          end

          after do
            object.reset_storage_options!
          end

          it 'uses the persistence context options' do
            expect(persistence_context.database_name).to eq(:musique)
          end
        end

        context 'when the storage options is a block' do

          before do
            object.store_in database: ->{ :sounds }
          end

          after do
            object.reset_storage_options!
          end

          it 'uses the persistence context options' do
            expect(persistence_context.database_name).to eq(:musique)
          end
        end
      end
    end

    context 'when storage options are not set on the object' do

      context 'when there are options passed to the Persistence Context' do

        let(:options) do
          { database: 'musique' }
        end

        it 'uses the persistence context options' do
          expect(persistence_context.database_name).to eq(:musique)
        end

        context 'when there is a database override' do
          persistence_context_override :database, :other

          it 'uses the persistence context options' do
            expect(persistence_context.database_name).to eq(:musique)
          end
        end
      end

      context 'when there are no options passed to the Persistence Context' do

        context 'when there is a database override' do
          persistence_context_override :database, :other

          it 'uses the database override options' do
            expect(persistence_context.database_name).to eq(Mongoid::Threaded.database_override)
          end
        end
      end
    end
  end

  describe '#client' do

    let(:persistence_context) do
      described_class.new(object, options)
    end

    let(:options) do
      { }
    end

    before do
      Mongoid.clients[:alternative] = { database: :mongoid_test, hosts: SpecConfig.instance.addresses }
    end

    after do
      Mongoid.clients.delete(:alternative)
    end

    context 'when the client is set in the options' do

      let(:options) do
        { client: :alternative }
      end

      after do
        persistence_context.client.close
      end

      it 'uses the client option' do
        expect(persistence_context.client).to eq(Mongoid::Clients.with_name(:alternative))
      end

      context 'when there is a client override' do
        persistence_context_override :client, :other

        it 'uses the client option' do
          expect(persistence_context.client).to eq(Mongoid::Clients.with_name(:alternative))
        end
      end

      context 'when there are storage options set' do

        after do
          object.reset_storage_options!
        end

        context 'when the storage options is static' do

          before do
            object.store_in client: :other
          end

          it 'uses the persistence context options' do
            expect(persistence_context.client).to eq(Mongoid::Clients.with_name(:alternative))
          end
        end

        context 'when the storage options is a block' do

          before do
            object.store_in client: ->{ :other }
          end

          it 'uses the persistence context options' do
            expect(persistence_context.client).to eq(Mongoid::Clients.with_name(:alternative))
          end
        end
      end
    end

    context 'when there is no client option set' do

      let(:options) do
        { }
      end

      context 'when there is a client override' do
        persistence_context_override :client, :alternative

        it 'uses the client override' do
          expect(persistence_context.client).to eq(Mongoid::Clients.with_name(:alternative))
        end
      end

      context 'when there are storage options set' do

        after do
          object.reset_storage_options!
        end

        context 'when the storage options is static' do

          before do
            object.store_in client: :alternative
          end

          it 'uses the client storage option' do
            expect(persistence_context.client).to eq(Mongoid::Clients.with_name(:alternative))
          end
        end

        context 'when the storage options is a block' do

          before do
            object.store_in client: ->{ :alternative }
          end

          it 'uses the client storage option' do
            expect(persistence_context.client).to eq(Mongoid::Clients.with_name(:alternative))
          end
        end

        context 'when there is a client override' do
          persistence_context_override :client, :alternative

          it 'uses the client override' do
            expect(persistence_context.client).to eq(Mongoid::Clients.with_name(:alternative))
          end
        end
      end
    end

    context 'when there are client options set' do

      let(:options) do
        { connect_timeout: 3 }
      end

      it 'applies the options to the client' do
        expect(persistence_context.client.options[:connect_timeout]).to eq(options[:connect_timeout])
      end
    end

    context 'when there is a database name set in the options' do

      let(:options) do
        { database: 'other' }
      end

      it 'uses the database from the options' do
        expect(persistence_context.client.database.name).to eq(options[:database])
      end
    end
  end

  context "when using an alternate database to update a document" do
    let(:user) do
      User.new(name: '1')
    end

    before do
      user.with(database: database_id_alt) do |u|
        u.save!
      end

      expect do
        user.with(database: database_id_alt) do |u|
          u.update(name:'2')
        end
      end.to_not raise_error
    end

    it "persists the update" do
      User.with("database" => database_id_alt) do |klass|
        expect(klass.find(user._id).name).to eq("2")
      end
    end
  end
end
