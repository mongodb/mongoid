# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Clients do

  describe "#collection" do

    shared_examples_for "an overridden collection at the class level" do

      it "returns the collection for the model" do
        expect(instance_collection).to be_a(Mongo::Collection)
      end

      it "sets the correct collection name" do
        expect(instance_collection.name).to eq("artists")
      end

      context "when accessing from the class level" do

        it "returns the collection for the model" do
          expect(class_collection).to be_a(Mongo::Collection)
        end

        it "sets the correct collection name" do
          expect(class_collection.name).to eq("artists")
        end
      end
    end

    context "when overriding the persistence options" do

      let(:instance_collection) do
        Band.with(collection: "artists") do |klass|
          klass.new.collection
        end
      end

      let(:class_collection) do
        Band.with(collection: "artists") do |klass|
          klass.collection
        end
      end

      it_behaves_like "an overridden collection at the class level"
    end

    context "when overriding store_in and persistence options" do

      before do
        Band.store_in collection: "foo"
      end

      after do
        Band.reset_storage_options!
      end

      let(:instance_collection) do
        Band.with(collection: "artists") do |klass|
          klass.new.collection
        end
      end

      let(:class_collection) do
        Band.with(collection: "artists") do |klass|
          klass.collection
        end
      end

      it_behaves_like "an overridden collection at the class level"
    end

    context "when overriding the default with store_in" do

      after do
        Band.reset_storage_options!
      end

      context "when called multiple times with different options" do

        before do
          Band.store_in collection: "artists"
          Band.store_in client: "another"
        end

        it "should merge the options together" do
          expect(Band.storage_options[:collection]).to eq("artists")
          expect(Band.storage_options[:client]).to eq("another")
        end
      end

      context "when overriding with a proc" do

        before do
          Band.store_in(collection: ->{ "artists" })
        end

        let(:instance_collection) do
          Band.new.collection
        end

        let(:class_collection) do
          Band.collection
        end

        it_behaves_like "an overridden collection at the class level"
      end

      context "when overriding with a string" do

        before do
          Band.store_in(collection: "artists")
        end

        after do
          Band.reset_storage_options!
        end

        let(:instance_collection) do
          Band.new.collection
        end

        let(:class_collection) do
          Band.collection
        end

        it_behaves_like "an overridden collection at the class level"
      end

      context "when overriding with a symbol" do

        before do
          Band.store_in(collection: :artists)
        end

        after do
          Band.reset_storage_options!
        end

        let(:instance_collection) do
          Band.new.collection
        end

        let(:class_collection) do
          Band.collection
        end

        it_behaves_like "an overridden collection at the class level"
      end
    end

    context "when not overriding the default" do

      let(:band) do
        Band.new
      end

      it "returns the collection for the model" do
        expect(band.collection).to be_a(Mongo::Collection)
      end

      it "sets the correct collection name" do
        expect(band.collection.name.to_s).to eq("bands")
      end

      context "when accessing from the class level" do

        it "returns the collection for the model" do
          expect(Band.collection).to be_a(Mongo::Collection)
        end

        it "sets the correct collection name" do
          expect(Band.collection.name.to_s).to eq("bands")
        end
      end
    end
  end

  describe "#collection_name" do

    shared_examples_for "an overridden collection name at the class level" do

      context "when accessing from the instance" do

        it "returns the overridden value" do
          expect(instance_collection_name).to eq(:artists)
        end
      end

      context "when accessing from the class level" do

        it "returns the overridden value" do
          expect(class_collection_name).to eq(:artists)
        end
      end
    end

    context "when overriding the persistence options" do

      let(:instance_collection_name) do
        Band.with(collection: "artists") do |klass|
          klass.new.collection_name
        end
      end

      let(:class_collection_name) do
        Band.with(collection: "artists") do |klass|
          klass.collection_name
        end
      end

      it_behaves_like "an overridden collection name at the class level"

      context 'when nesting #with calls' do
        let(:instance_collection_name) do
          Band.with(collection: "ignore") do |klass|
            Band.with(collection: "artists") do |klass|
              klass.new.collection_name
            end
          end
        end

        let(:class_collection_name) do
          Band.with(collection: "ignore") do |klass|
            Band.with(collection: "artists") do |klass|
              klass.collection_name
            end
          end
        end

        it_behaves_like "an overridden collection name at the class level"
      end

      context 'when outer #with call specifies the collection' do
        use_spec_mongoid_config

        let(:instance_collection_name) do
          Band.with(collection: "artists") do |klass|
            Band.with(client: :reports) do |klass|
              klass.new.collection_name
            end
          end
        end

        let(:class_collection_name) do
          Band.with(collection: "artists") do |klass|
            Band.with(client: :reports) do |klass|
              klass.collection_name
            end
          end
        end

        it_behaves_like "an overridden collection name at the class level"
      end

      context 'restores outer context in outer block' do
        use_spec_mongoid_config

        let(:instance_collection_name) do
          Band.with(collection: "artists") do |klass|
            Band.with(collection: "scratch") do |klass|
              # nothing
            end
            klass.new.collection_name
          end
        end

        let(:class_collection_name) do
          Band.with(collection: "artists") do |klass|
            Band.with(collection: "scratch") do |klass|
              # nothing
            end
            klass.collection_name
          end
        end

        it_behaves_like "an overridden collection name at the class level"
      end
    end

    context "when overriding store_in and persistence options" do

      let(:instance_collection_name) do
        Band.with(collection: "artists") do |klass|
          klass.new.collection_name
        end
      end

      let(:class_collection_name) do
        Band.with(collection: "artists") do |klass|
          klass.collection_name
        end
      end

      before do
        Band.store_in collection: "foo"
      end

      after do
        Band.reset_storage_options!
      end

      it_behaves_like "an overridden collection name at the class level"
    end

    context "when overriding the default with store_in" do

      let(:instance_collection_name) do
        Band.new.collection_name
      end

      let(:class_collection_name) do
        Band.collection_name
      end

      after do
        Band.reset_storage_options!
      end

      context "when overriding with a proc" do

        before do
          Band.store_in(collection: ->{ "artists" })
        end

        it_behaves_like "an overridden collection name at the class level"
      end

      context "when overriding with a string" do

        before do
          Band.store_in(collection: "artists")
        end

        it_behaves_like "an overridden collection name at the class level"
      end

      context "when overriding with a symbol" do

        before do
          Band.store_in(collection: :artists)
        end

        it_behaves_like "an overridden collection name at the class level"
      end
    end

    context "when not overriding the default" do

      let(:band) do
        Band.new
      end

      it "returns the pluralized model name" do
        expect(band.collection_name).to eq(:bands)
      end

      context "when accessing from the class level" do

        it "returns the pluralized model name" do
          expect(Band.collection_name).to eq(:bands)
        end
      end
    end

    context "when the model is a subclass" do

      let(:firefox) do
        Firefox.new
      end

      it "returns the root class pluralized model name" do
        expect(firefox.collection_name).to eq(:canvases)
      end

      context "when accessing from the class level" do

        it "returns the root class pluralized model name" do
          expect(Firefox.collection_name).to eq(:canvases)
        end
      end
    end
  end

  describe "#database_name" do

    shared_examples_for "an overridden database name" do

      after do
        class_mongo_client.close
      end

      context "when accessing from the instance" do

        it "returns the overridden value" do
          expect(instance_database.name.to_s).to eq(database_id_alt)
        end
      end

      context "when accessing from the class level" do

        it "returns the overridden value" do
          expect(class_database.name.to_s).to eq(database_id_alt)
        end

        it "client returns the overridden value" do
          expect(class_mongo_client.database.name).to eq(database_id_alt)
        end
      end
    end

    context "when overriding the persistence options" do

      let(:instance_database) do
        Band.with(database: database_id_alt) do |klass|
          klass.new.mongo_client.database
        end
      end

      let(:class_database) do
        Band.with(database: database_id_alt) do |klass|
          klass.mongo_client.database
        end
      end

      let(:class_mongo_client) do
        Band.with(database: database_id_alt) do |klass|
          klass.new.mongo_client
        end
      end

      it_behaves_like "an overridden database name"
    end

    context "when overriding with store_in" do

      let(:instance_database) do
        Band.new.mongo_client.database
      end

      let(:class_database) do
        Band.mongo_client.database
      end

      let(:class_mongo_client) do
        Band.mongo_client
      end

      before do
        Band.store_in database: database_id_alt
      end

      after do
        Band.reset_storage_options!
        class_mongo_client.close
      end

      it_behaves_like "an overridden database name"
    end

    context "when overriding store_in and persistence options" do

      let(:instance_database) do
        Band.with(database: database_id_alt) do |klass|
          klass.new.mongo_client.database
        end
      end

      let(:class_database) do
        Band.with(database: database_id_alt) do |klass|
          klass.mongo_client.database
        end
      end

      let(:class_mongo_client) do
        Band.with(database: database_id_alt) do |klass|
          klass.new.mongo_client
        end
      end

      before do
        Band.store_in database: "foo"
      end

      after do
        Band.reset_storage_options!
        class_mongo_client.close
      end

      it_behaves_like "an overridden database name"
    end

    context "when overriding using the client" do

      let(:client_name) { :alternative }

      before do
        Mongoid.clients[client_name] = { database: database_id_alt, hosts: SpecConfig.instance.addresses }
      end

      after do
        Mongoid.clients.delete(client_name)
      end

      context "when overriding the persistence options" do

        let(:instance_database) do
          Band.with(client: :alternative) do |klass|
            klass.new.mongo_client.database
          end
        end

        let(:class_database) do
          Band.with(client: :alternative) do |klass|
            klass.mongo_client.database
          end
        end

        let(:class_mongo_client) do
          Band.with(client: :alternative) do |klass|
            klass.new.mongo_client
          end
        end

        it_behaves_like "an overridden database name"
      end

      context "when overriding with store_in" do

        let(:instance_database) do
          Band.new.mongo_client.database
        end

        let(:class_database) do
          Band.mongo_client.database
        end

        let(:class_mongo_client) do
          Band.mongo_client
        end

        before do
          Band.store_in(client: client_name)
        end

        after do
          Band.reset_storage_options!
          class_mongo_client.close
        end

        it_behaves_like "an overridden database name"
      end
    end
  end

  describe "#mongo_client" do

    let(:file) do
      File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
    end

    before do
      described_class.clear
      Mongoid.load!(file, :test)
      Mongoid.clients[:default][:database] = database_id
    end

    context "when getting the default" do

      let(:file) do
        File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
      end

      before do
        described_class.clear
        Mongoid.load!(file, :test)
        Mongoid.clients[:default][:database] = database_id
      end

      after do
        mongo_client.close
      end

      let!(:band) do
        Band.new
      end

      let!(:mongo_client) do
        band.mongo_client
      end

      it "returns the default client" do
        expect(mongo_client.options[:database].to_s).to eq(database_id)
      end

      it "sets the platform to Mongoid's platform constant" do
        expect(mongo_client.options[:platform]).to eq(Mongoid::PLATFORM_DETAILS)
      end

      it "sets the app_name to the config value" do
        expect(mongo_client.options[:app_name]).to eq('testing')
      end
    end

    context "when no client exists with the key" do

      before(:all) do
        Band.store_in(client: :nonexistent)
      end

      let(:band) do
        Band.new
      end

      it "raises an error" do
        expect {
          band.mongo_client
        }.to raise_error(Mongoid::Errors::NoClientConfig)
      end
    end

    context "when getting a client by name" do
      use_spec_mongoid_config

      before do
        Band.store_in(client: :reports)
      end

      after do
        mongo_client.close
        Band.reset_storage_options!
      end

      let(:mongo_client) do
        Band.new.mongo_client
      end

      it "uses the reports client" do
        expect(mongo_client.options[:database].to_s).to eq('reports')
      end

      it "sets the platform to Mongoid's platform constant" do
        expect(mongo_client.options[:platform]).to eq(Mongoid::PLATFORM_DETAILS)
      end

      it "sets the app_name to the config value" do
        expect(mongo_client.options[:app_name]).to eq('testing')
      end
    end

    context 'when the app_name is not set in the config' do

      before do
        Mongoid::Config.reset
        Mongoid.configure do |config|
          config.load_configuration(CONFIG)
        end
      end

      let(:mongo_client) do
        Band.new.mongo_client
      end

      it 'does not set the Mongoid.app_name option' do
        expect(mongo_client.options.has_key?(:app_name)).to be(false)
      end
    end
  end

  describe ".mongo_client" do

    let(:file) do
      File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
    end

    before do
      described_class.clear
      Mongoid.load!(file, :test)
      Mongoid.clients[:default][:database] = database_id
    end

    after do
      Band.reset_storage_options!
    end

    context "when getting the default" do

      let(:file) do
        File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
      end

      before do
        Band.reset_storage_options!
        described_class.clear
        Mongoid.load!(file, :test)
        Mongoid.clients[:default][:database] = database_id
      end

      let!(:mongo_client) do
        Band.mongo_client
      end

      it "returns the default client" do
        expect(mongo_client.options[:database].to_s).to eq(database_id)
      end

      it "sets the platform to Mongoid's platform constant" do
        expect(mongo_client.options[:platform]).to eq(Mongoid::PLATFORM_DETAILS)
      end

      it "sets the app_name to the config value" do
        expect(mongo_client.options[:app_name]).to eq('testing')
      end
    end

    context "when no client exists with the key" do

      before(:all) do
        Band.store_in(client: :nonexistent)
      end

      it "raises an error" do
        expect {
          Band.mongo_client
        }.to raise_error(Mongoid::Errors::NoClientConfig)
      end
    end
  end

  describe ".store_in" do

    context "when provided a non hash" do

      it "raises an error" do
        expect {
          Band.store_in :artists
        }.to raise_error(Mongoid::Errors::InvalidStorageOptions)
      end
    end

    context "when provided a hash" do

      context "when the hash is not valid" do

        it "raises an error" do
          expect {
            Band.store_in coll: "artists"
          }.to raise_error(Mongoid::Errors::InvalidStorageOptions)
        end
      end
    end

    context "when it is called on a subclass" do

      let(:client) { StoreParent.collection.client }
      let(:parent) { StoreParent.create! }
      let(:child1) { StoreChild1.create! }
      let(:child2) { StoreChild2.create! }

      before do
        class StoreParent
          include Mongoid::Document
        end

        class StoreChild1 < StoreParent
        end

        class StoreChild2 < StoreParent
        end
      end

      after do
        Object.send(:remove_const, :StoreParent)
        Object.send(:remove_const, :StoreChild1)
        Object.send(:remove_const, :StoreChild2)
      end

      context "when it is not called on the parent" do

        context "when it is called on all subclasses" do

          before do
            StoreChild1.store_in collection: :store_ones
            StoreChild2.store_in collection: :store_twos
            [ parent, child1, child2 ]
          end

          let(:db_parent) { client['store_parents'].find.first }
          let(:db_child1) { client['store_ones'].find.first }
          let(:db_child2) { client['store_twos'].find.first }

          it "stores the documents in the correct collections" do
            expect(db_parent).to eq({ "_id" => parent.id, "_type" => "StoreParent" })
            expect(db_child1).to eq({ "_id" => child1.id, "_type" => "StoreChild1" })
            expect(db_child2).to eq({ "_id" => child2.id, "_type" => "StoreChild2" })
          end

          it "only queries from its own collections" do
            expect(StoreParent.count).to eq(1)
            expect(StoreChild1.count).to eq(1)
            expect(StoreChild2.count).to eq(1)
          end
        end

        context "when it is called on one of the subclasses" do

          before do
            StoreChild1.store_in collection: :store_ones
            [ parent, child1, child2 ]
          end

          let(:db_parent) { client['store_parents'].find.first }
          let(:db_child1) { client['store_ones'].find.first }
          let(:db_child2) { client['store_parents'].find.to_a.last }

          it "stores the documents in the correct collections" do
            expect(db_parent).to eq({ "_id" => parent.id, "_type" => "StoreParent" })
            expect(db_child1).to eq({ "_id" => child1.id, "_type" => "StoreChild1" })
            expect(db_child2).to eq({ "_id" => child2.id, "_type" => "StoreChild2" })
          end

          it "queries from its own collections" do
            expect(StoreParent.count).to eq(2)
            expect(StoreChild1.count).to eq(1)
            expect(StoreChild2.count).to eq(1)
          end
        end
      end

      context "when it is called on the parent" do

        before do
          StoreParent.store_in collection: :st_parents
        end

        context "when it is called on all subclasses" do

          before do
            StoreChild1.store_in collection: :store_ones
            StoreChild2.store_in collection: :store_twos
            [ parent, child1, child2 ]
          end

          let(:db_parent) { client['st_parents'].find.first }
          let(:db_child1) { client['store_ones'].find.first }
          let(:db_child2) { client['store_twos'].find.first }

          it "stores the documents in the correct collections" do
            expect(db_parent).to eq({ "_id" => parent.id, "_type" => "StoreParent" })
            expect(db_child1).to eq({ "_id" => child1.id, "_type" => "StoreChild1" })
            expect(db_child2).to eq({ "_id" => child2.id, "_type" => "StoreChild2" })
          end
        end

        context "when it is called on one of the subclasses" do

          before do
            StoreChild1.store_in collection: :store_ones
            [ parent, child1, child2 ]
          end

          let(:db_parent) { client['st_parents'].find.first }
          let(:db_child1) { client['store_ones'].find.first }
          let(:db_child2) { client['st_parents'].find.to_a.last }

          it "stores the documents in the correct collections" do
            expect(db_parent).to eq({ "_id" => parent.id, "_type" => "StoreParent" })
            expect(db_child1).to eq({ "_id" => child1.id, "_type" => "StoreChild1" })
            expect(db_child2).to eq({ "_id" => child2.id, "_type" => "StoreChild2" })
          end
        end
      end
    end
  end

  describe ".with" do

    context "when changing write concern options" do

      let(:client_one) do
        Band.with(write: { w: 2 }) do |klass|
          klass.mongo_client
        end
      end

      let(:client_two) do
        Band.mongo_client
      end

      it "does not carry over the options" do
        expect(client_one.write_concern).to_not eq(client_two.write_concern)
      end
    end

    context "when sending operations to a different database" do

      after do
        Band.with(database: database_id_alt) do |klass|
          klass.delete_all
        end
      end

      describe ".create!" do

        let!(:band) do
          Band.with(database: database_id_alt) do |klass|
            klass.create!
          end
        end

        it "does not persist to the default database" do
          expect {
            Band.find(band.id)
          }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Band with id\(s\)/)
        end

        let(:from_db) do
          Band.with(database: database_id_alt) do |klass|
            klass.find(band.id)
          end
        end

        it "persists to the specified database" do
          expect(from_db).to eq(band)
        end

        let(:count) do
          Band.with(database: database_id_alt) do |klass|
            klass.count
          end
        end

        it "persists the correct number of documents" do
          expect(count).to eq(1)
        end
      end
    end

    context "when sending operations to a different collection" do

      describe ".create!" do

        let!(:band) do
          Band.with(collection: "artists") do |klass|
            klass.create!
          end
        end

        it "does not persist to the default database" do
          expect {
            Band.find(band.id)
          }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Band with id\(s\)/)
        end

        let(:from_db) do
          Band.with(collection: "artists") do |klass|
            klass.find(band.id)
          end
        end

        it "persists to the specified database" do
          expect(from_db).to eq(band)
        end

        let(:count) do
          Band.with(collection: "artists") do |klass|
            klass.count
          end
        end

        it "persists the correct number of documents" do
          expect(count).to eq(1)
        end
      end
    end

    context "when sending operations with safe mode" do

      describe ".create" do

        before do
          Person.index({ ssn: 1 }, { unique: true })
          Person.create_indexes
          Person.create(ssn: "432-97-1111")
        end

        after do
          Person.collection.drop
        end

        context "when no error occurs" do

          it "inserts the document" do
            expect(Person.count).to eq(1)
          end
        end

        context "when a mongodb error occurs" do

          it "bubbles up to the caller" do
            expect {
              Person.create(ssn: "432-97-1111")
            }.to raise_error(Mongo::Error::OperationFailure)
          end
        end
      end

      describe ".create!" do

        before do
          Person.create!(ssn: "432-97-1112")
        end

        after do
          Person.collection.drop
        end

        context "when no error occurs" do

          it "inserts the document" do
            expect(Person.count).to eq(1)
          end
        end

        context "when a mongodb error occurs" do

          before do
            Person.index({ ssn: 1 }, { unique: true })
            Person.create_indexes
          end

          after do
            Person.collection.drop
          end

          it "bubbles up to the caller" do
            expect {
              Person.create!(ssn: "432-97-1112")
            }.to raise_error(Mongo::Error::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          it "raises the validation error" do
            expect {
              Account.create!(name: "this name is way too long")
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end

      describe ".save" do

        before do
          Person.create!(ssn: "432-97-1113")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(ssn: "432-97-1113")
          end

          before do
            Person.index({ ssn: 1 }, { unique: true })
            Person.create_indexes
          end

          after do
            Person.collection.drop
          end

          it "bubbles up to the caller" do
            expect {
              person.save
            }.to raise_error(Mongo::Error::OperationFailure)
          end
        end
      end

      describe ".save!" do

        before do
          Person.create!(ssn: "432-97-1114")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(ssn: "432-97-1114")
          end

          before do
            Person.index({ ssn: 1 }, { unique: true })
            Person.create_indexes
          end

          after do
            Person.collection.drop
          end

          it "bubbles up to the caller" do
            expect {
              person.save!
            }.to raise_error(Mongo::Error::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          let(:account) do
            Account.new(name: "this name is way too long")
          end

          it "raises the validation error" do
            expect {
              account.save!
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end

    context 'when requesting named client' do
      let(:secondary_client) do
        double(Mongo::Client).tap do |client|
          allow(client).to receive(:cluster).and_return(double("cluster"))
        end
      end

      before do
        expect(Mongoid::Clients::Factory).to receive(:create)
          .with(:secondary)
          .and_return(secondary_client)
      end

      after do
        Mongoid::Clients.clients.delete(:secondary)
      end

      it 'does not close the client' do
        expect(secondary_client).not_to receive(:close)

        Band.with(client: :default) do |klass|
          klass.mongo_client
        end

        Band.with(client: :secondary) do |klass|
          klass.mongo_client
        end
      end
    end

    context 'when using on different objects' do
      require_mri

      let(:first_band) do
        Band.create!(name: "The Beatles")
      end

      let(:second_band) do
        Band.create!(name: 'Led Zeppelin')
      end

      it 'does not create extra symbols symbols' do
        first_band.with(write: { w: 0, j: false }) do |band|
          band.set(active: false)
        end
        initial_symbols_count = Symbol.all_symbols.size
        second_band.with(write: { w: 0, j: false }) do |band|
          band.set(active: false)
        end
        expect(Symbol.all_symbols.size).to eq(initial_symbols_count)
      end

    end

  end

  context "when overriding the default database" do

    let(:file) do
      File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
    end

    before do
      Mongoid::Config.load!(file, :test)
    end

    context "when the override is global" do

      before do
        Mongoid.override_database(:mongoid_optional)
      end

      after do
        Band.delete_all
        Band.mongo_client.close
        Mongoid.override_database(nil)
      end

      let!(:band) do
        Band.create!(name: "Tool")
      end

      it "persists to the overridden database" do
        Band.mongo_client.with(database: :mongoid_optional) do |sess|
          expect(sess[:bands].find(name: "Tool")).to_not be_nil
        end
      end

      it 'uses that database for the model mongo_client' do
        expect(Band.mongo_client.database.name).to eq('mongoid_optional')
      end
    end
  end
end
