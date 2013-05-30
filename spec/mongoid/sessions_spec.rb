require "spec_helper"

describe Mongoid::Sessions do

  describe ".clear_persistence_options" do

    context "when options exist on the current thread" do

      before do
        Band.with(safe: true)
      end

      let!(:cleared) do
        Band.clear_persistence_options
      end

      it "remove the options from the current thread" do
        Band.persistence_options.should be_nil
      end

      it "returns true" do
        cleared.should be_true
      end
    end

    context "when options do not exist on the current thread" do

      it "returns true" do
        Band.clear_persistence_options.should be_true
      end
    end
  end

  describe "#collection" do

    context "when overriding the default with store_in" do

      shared_examples_for "an overridden collection at the class level" do

        let(:band) do
          Band.new
        end

        it "returns the collection for the model" do
          band.collection.should be_a(Moped::Collection)
        end

        it "sets the correct collection name" do
          band.collection.name.to_s.should eq("artists")
        end

        context "when accessing from the class level" do

          it "returns the collection for the model" do
            Band.collection.should be_a(Moped::Collection)
          end

          it "sets the correct collection name" do
            Band.collection.name.to_s.should eq("artists")
          end
        end

        context "when safety options exist" do

          context "when the options are from the current thread" do

            before do
              Band.with(safe: { w: 3 })
            end

            it "clears the options from the current thread" do
              Band.collection
              Band.persistence_options.should be_nil
            end

            it "returns the collection" do
              Band.collection.should be_a(Moped::Collection)
            end
          end
        end
      end

      after do
        Band.storage_options = nil
      end

      context "when called multiple times with different options" do
        before do
          Band.store_in collection: "artists"
          Band.store_in session: "another"
        end

        it "should merge the options together" do
          Band.storage_options.should == {
            collection: "artists",
            session: "another"
          }
        end
      end

      context "when overriding with a proc" do

        before do
          Band.store_in(collection: ->{ "artists" })
        end

        it_behaves_like "an overridden collection at the class level"
      end

      context "when overriding with a string" do

        before do
          Band.store_in(collection: "artists")
        end

        it_behaves_like "an overridden collection at the class level"
      end

      context "when overriding with a symbol" do

        before do
          Band.store_in(collection: :artists)
        end

        it_behaves_like "an overridden collection at the class level"
      end
    end

    context "when not overriding the default" do

      let(:band) do
        Band.new
      end

      it "returns the collection for the model" do
        band.collection.should be_a(Moped::Collection)
      end

      it "sets the correct collection name" do
        band.collection.name.to_s.should eq("bands")
      end

      context "when accessing from the class level" do

        it "returns the collection for the model" do
          Band.collection.should be_a(Moped::Collection)
        end

        it "sets the correct collection name" do
          Band.collection.name.to_s.should eq("bands")
        end
      end
    end
  end

  describe "#collection_name" do

    context "when overriding the default with store_in" do

      shared_examples_for "an overridden collection name at the class level" do

        let(:band) do
          Band.new
        end

        context "when accessing from the instance" do

          it "returns the overridden value" do
            band.collection_name.should eq(:artists)
          end
        end

        context "when accessing from the class level" do

          it "returns the overridden value" do
            Band.collection_name.should eq(:artists)
          end
        end
      end

      after do
        Band.storage_options = nil
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
        band.collection_name.should eq(:bands)
      end

      context "when accessing from the class level" do

        it "returns the pluralized model name" do
          Band.collection_name.should eq(:bands)
        end
      end
    end

    context "when the model is a subclass" do

      let(:firefox) do
        Firefox.new
      end

      it "returns the root class pluralized model name" do
        firefox.collection_name.should eq(:canvases)
      end

      context "when accessing from the class level" do

        it "returns the root class pluralized model name" do
          Firefox.collection_name.should eq(:canvases)
        end
      end
    end
  end

  describe "#mongo_session" do

    let(:file) do
      File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
    end

    before do
      described_class.clear
      Mongoid.load!(file, :test)
      Mongoid.sessions[:default][:database] = database_id
    end

    after do
      Band.storage_options = nil
    end

    context "when getting the default" do

      let(:file) do
        File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
      end

      before do
        Band.storage_options = nil
        described_class.clear
        Mongoid.load!(file, :test)
        Mongoid.sessions[:default][:database] = database_id
      end

      after do
        Band.storage_options = nil
      end

      let!(:band) do
        Band.new
      end

      let!(:mongo_session) do
        band.mongo_session
      end

      it "returns the default session" do
        mongo_session.options[:database].should eq(database_id)
      end
    end

    context "when overriding to a monghq single server", config: :mongohq do

      shared_examples_for "an overridden session to a mongohq single server" do

        let(:band) do
          Band.new
        end

        let(:single_session) do
          band.mongo_session
        end

        it "returns the default session" do
          single_session.options[:database].should eq(ENV["MONGOHQ_SINGLE_NAME"])
        end
      end

      context "when overriding with a proc" do

        before do
          Band.store_in(session: ->{ :mongohq_single })
        end

        it_behaves_like "an overridden session to a mongohq single server"
      end

      context "when overriding with a string" do

        before do
          Band.store_in(session: "mongohq_single")
        end

        it_behaves_like "an overridden session to a mongohq single server"
      end

      context "when overriding with a symbol" do

        before do
          Band.store_in(session: :mongohq_single)
        end

        it_behaves_like "an overridden session to a mongohq single server"
      end
    end

    context "when overriding to a mongohq replica set", config: :mongohq do

      let(:band) do
        Band.new
      end

      let(:replica_session) do
        band.mongo_session
      end

      shared_examples_for "an overridden session to a mongohq replica set" do

        it "returns the default session" do
          replica_session.options[:database].should eq(ENV["MONGOHQ_REPL_NAME"])
        end
      end

      context "when overriding with a proc" do

        before do
          Band.store_in(session: ->{ :mongohq_repl })
        end

        it_behaves_like "an overridden session to a mongohq replica set"
      end

      context "when overriding with a string" do

        before do
          Band.store_in(session: "mongohq_repl")
        end

        it_behaves_like "an overridden session to a mongohq replica set"
      end

      context "when overriding with a symbol" do

        before do
          Band.store_in(session: :mongohq_repl)
        end

        it_behaves_like "an overridden session to a mongohq replica set"
      end
    end

    context "when overriding to a mongohq replica set with uri config", config: :mongohq do

      before(:all) do
        Band.store_in(session: :mongohq_repl_uri)
      end

      let(:band) do
        Band.new
      end

      let(:repl_session) do
        band.mongo_session
      end

      it "returns the default session" do
        repl_session.options[:database].should eq(ENV["MONGOHQ_REPL_NAME"])
      end
    end

    context "when no session exists with the key" do

      before(:all) do
        Band.store_in(session: :nonexistant)
      end

      let(:band) do
        Band.new
      end

      it "raises an error" do
        expect {
          band.mongo_session
        }.to raise_error(Mongoid::Errors::NoSessionConfig)
      end
    end
  end

  describe ".mongo_session" do

    let(:file) do
      File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
    end

    before do
      described_class.clear
      Mongoid.load!(file, :test)
      Mongoid.sessions[:default][:database] = database_id
    end

    after do
      Band.storage_options = nil
    end

    context "when getting the default" do

      let(:file) do
        File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
      end

      before do
        Band.storage_options = nil
        described_class.clear
        Mongoid.load!(file, :test)
        Mongoid.sessions[:default][:database] = database_id
      end

      let!(:mongo_session) do
        Band.mongo_session
      end

      it "returns the default session" do
        mongo_session.options[:database].should eq(database_id)
      end
    end

    context "when overriding to a monghq single server", config: :mongohq do

      before(:all) do
        Band.store_in(session: :mongohq_single)
      end

      let(:session) do
        Band.mongo_session
      end

      it "returns the default session" do
        session.options[:database].should eq(ENV["MONGOHQ_SINGLE_NAME"])
      end
    end

    context "when overriding to a mongohq replica set", config: :mongohq do

      before(:all) do
        Band.store_in(session: :mongohq_repl)
      end

      let(:repl_session) do
        Band.mongo_session
      end

      it "returns the default session" do
        repl_session.options[:database].should eq(ENV["MONGOHQ_REPL_NAME"])
      end
    end

    context "when no session exists with the key" do

      before(:all) do
        Band.store_in(session: :nonexistant)
      end

      it "raises an error" do
        expect {
          Band.mongo_session
        }.to raise_error(Mongoid::Errors::NoSessionConfig)
      end
    end
  end

  describe ".persistence_options" do

    context "when options exist on the current thread" do

      before do
        Band.with(safe: { w: 2 })
      end

      after do
        Band.clear_persistence_options
      end

      it "returns the options" do
        Band.persistence_options.should eq(safe: { w: 2 })
      end
    end

    context "when there are no options on the current thread" do

      it "returns nil" do
        Band.persistence_options.should be_nil
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
  end

  describe ".with" do

    context "when sending operations to a different database" do

      after do
        Band.with(database: "mongoid_test_alt").delete_all
      end

      describe ".create" do

        let!(:band) do
          Band.with(database: "mongoid_test_alt").create
        end

        it "does not persist to the default database" do
          expect {
            Band.find(band.id)
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end

        let(:from_db) do
          Band.with(database: "mongoid_test_alt").find(band.id)
        end

        it "persists to the specified database" do
          from_db.should eq(band)
        end

        it "persists the correct number of documents" do
          Band.with(database: "mongoid_test_alt").count.should eq(1)
        end
      end

      describe ".map_reduce", config: :mongohq do

        let(:map) do
          %Q{
          function() {
            emit(this.name, { likes: this.likes });
          }}
        end

        let(:reduce) do
          %Q{
          function(key, values) {
            var result = { likes: 0 };
            values.forEach(function(value) {
              result.likes += value.likes;
            });
            return result;
          }}
        end

        before do
          Band.with(database: "mongoid_test_alt").delete_all
        end

        let!(:depeche_mode) do
          Band.with(database: "mongoid_test_alt").
            create(name: "Depeche Mode", likes: 200)
        end

        let!(:tool) do
          Band.with(database: "mongoid_test_alt").
            create(name: "Tool", likes: 100)
        end

        context "when outputting in memory" do

          let(:results) do
            Band.with(database: "mongoid_test_alt").
              map_reduce(map, reduce).out(inline: 1)
          end

          it "executes the map/reduce on the correct database" do
            results.first["value"].should eq({ "likes" => 200 })
          end
        end

        context "when outputting to a collection" do

          let(:results) do
            Band.with(database: "mongoid_test_alt").
              map_reduce(map, reduce).out(replace: "bands_output")
          end

          it "executes the map/reduce on the correct database" do
            results.first["value"].should eq({ "likes" => 200 })
          end
        end
      end
    end

    context "when sending operations to a different collection" do

      describe ".create" do

        let!(:band) do
          Band.with(collection: "artists").create
        end

        it "does not persist to the default database" do
          expect {
            Band.find(band.id)
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end

        let(:from_db) do
          Band.with(collection: "artists").find(band.id)
        end

        it "persists to the specified database" do
          from_db.should eq(band)
        end

        it "persists the correct number of documents" do
          Band.with(collection: "artists").count.should eq(1)
        end
      end

      describe ".map_reduce", config: :mongohq do

        let(:map) do
          %Q{
          function() {
            emit(this.name, { likes: this.likes });
          }}
        end

        let(:reduce) do
          %Q{
          function(key, values) {
            var result = { likes: 0 };
            values.forEach(function(value) {
              result.likes += value.likes;
            });
            return result;
          }}
        end

        before do
          Band.with(collection: "artists").delete_all
        end

        let!(:depeche_mode) do
          Band.with(collection: "artists").
            create(name: "Depeche Mode", likes: 200)
        end

        let!(:tool) do
          Band.with(collection: "artists").
            create(name: "Tool", likes: 100)
        end

        let(:results) do
          Band.with(collection: "artists").
            map_reduce(map, reduce).out(inline: 1)
        end

        it "executes the map/reduce on the correct collection" do
          results.first["value"].should eq({ "likes" => 200 })
        end
      end
    end

    context "when sending operations to a different session" do

      describe ".create" do

        let(:file) do
          File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
        end

        before do
          described_class.clear
          Mongoid.load!(file, :test)
        end

        context "when sending to a mongohq single server", config: :mongohq do

          let!(:band) do
            Band.with(
              session: "mongohq_single",
              database: database_id
            ).create
          end

          let(:from_db) do
            Band.with(
              session: "mongohq_single",
              database: database_id
            ).find(band.id)
          end

          it "persists to the specified database" do
            from_db.should eq(band)
          end
        end

        context "when sending to a mongohq replica set", config: :mongohq do

          let!(:band) do
            Band.with(
              session: "mongohq_repl",
              database: "mongoid_replica"
            ).create
          end

          let(:from_db) do
            Band.with(
              session: "mongohq_repl",
              database: "mongoid_replica"
            ).find(band.id)
          end

          it "persists to the specified database" do
            from_db.should eq(band)
          end
        end

        context "when sending to a mongohq replica set with uri config", config: :mongohq do

          let!(:band) do
            Band.with(
              session: "mongohq_repl_uri",
              database: "mongoid_replica"
            ).create
          end

          let(:from_db) do
            Band.with(
              session: "mongohq_repl_uri",
              database: "mongoid_replica"
            ).find(band.id)
          end

          it "persists to the specified database" do
            from_db.should eq(band)
          end
        end
      end

      describe ".map_reduce", config: :mongohq do

        let(:file) do
          File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
        end

        before do
          described_class.clear
          Mongoid.load!(file, :test)
        end

        let(:map) do
          %Q{
          function() {
            emit(this.name, { likes: this.likes });
          }}
        end

        let(:reduce) do
          %Q{
          function(key, values) {
            var result = { likes: 0 };
            values.forEach(function(value) {
              result.likes += value.likes;
            });
            return result;
          }}
        end

        before do
          Band.with(
            session: "mongohq_repl",
            database: "mongoid_replica"
          ).delete_all
        end

        let!(:depeche_mode) do
          Band.with(
            session: "mongohq_repl",
            database: "mongoid_replica"
          ).create(name: "Depeche Mode", likes: 200)
        end

        let!(:tool) do
          Band.with(
            session: "mongohq_repl",
            database: "mongoid_replica"
          ).create(name: "Tool", likes: 100)
        end

        let(:results) do
          Band.with(
            session: "mongohq_repl",
            database: "mongoid_replica"
          ).map_reduce(map, reduce).out(inline: 1)
        end

        it "executes the map/reduce on the correct session" do
          results.first["value"].should eq({ "likes" => 200 })
        end
      end
    end

    context "when sending operations with safe mode" do

      describe ".create" do

        before do
          Person.with(safe: true).create(ssn: "432-97-1111")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should eq(1)
          end
        end

        context "when a mongodb error occurs" do

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              Person.with(safe: true).create(ssn: "432-97-1111")
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end

        context "when using safe: false" do

          it "ignores mongodb error" do
            Person.with(safe: false).create(ssn: "432-97-1111").should be_true
          end
        end
      end

      describe ".create!" do

        before do
          Person.with(safe: true).create!(ssn: "432-97-1112")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should eq(1)
          end
        end

        context "when a mongodb error occurs" do

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              Person.with(safe: true).create!(ssn: "432-97-1112")
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          it "raises the validation error" do
            expect {
              Account.with(safe: true).create!(name: "this name is way too long")
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end

      describe ".save" do

        before do
          Person.with(safe: true).create(ssn: "432-97-1113")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(ssn: "432-97-1113")
          end

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              person.with(safe: true).save
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end
      end

      describe ".save!" do

        before do
          Person.with(safe: true).create!(ssn: "432-97-1114")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(ssn: "432-97-1114")
          end

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              person.with(safe: true).save!
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          let(:account) do
            Account.new(name: "this name is way too long")
          end

          it "raises the validation error" do
            expect {
              account.with(safe: true).save!
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end
  end

  context "when the default database uses a uri" do

    let(:file) do
      File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
    end

    let(:config) do
      { default: { uri: "mongodb://localhost:#{PORT}/#{database_id}" }}
    end

    before do
      Mongoid::Threaded.sessions.clear
      Mongoid.sessions = config
    end

    context "when creating a document" do

      let!(:band) do
        Band.create(name: "Placebo")
      end

      it "persists the document to the correct database" do
        Band.find(band.id).should eq(band)
      end
    end
  end

  context "when overriding the default database "do

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
        Mongoid.override_database(nil)
      end

      let!(:band) do
        Band.create(name: "Tool")
      end

      it "persists to the overridden database" do
        Band.mongo_session.with(database: :mongoid_optional) do |sess|
          sess[:bands].find(name: "Tool").should_not be_nil
        end
      end
    end
  end

  context "when overriding the default session", config: :mongohq do

    context "when the override is configured with a uri" do

      let(:database_name) do
        "mongoid_other"
      end

      let(:config) do
        {  default: { uri: "mongodb://localhost:#{PORT}/#{database_id}" },
          session1: { uri: "mongodb://localhost:#{PORT}/#{database_name}" }}
      end

      before do
        Mongoid::Threaded.sessions.clear
        Mongoid.sessions = config
        Mongoid.override_session(:session1)
      end

      after do
        Mongoid.override_session(nil)
      end

      it "has some database name on session" do
        Band.mongo_session.options[:database].should eq(database_name)
      end
    end

    context "when the override is global" do

      let(:file) do
        File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
      end

      before do
        Mongoid::Config.load!(file, :test)
        Mongoid.override_session(:mongohq_single)
      end

      after do
        Band.with(database: database_id).delete_all
        Mongoid.override_session(nil)
      end

      let!(:band) do
        Band.with(database: database_id).create(name: "Tool")
      end

      let(:persisted) do
        Band.with(session: :mongohq_single, database: database_id).where(name: "Tool").first
      end

      it "persists to the overridden session" do
        persisted.should eq(band)
      end
    end
  end
end
