require "spec_helper"

describe Mongoid::Sessions do

  describe "#collection" do

    let(:config) do
      { default: { hosts: [ "localhost:27017" ] }}
    end

    let(:database_config) do
      { default: { name: database_id }}
    end

    let(:session) do
      Mongoid::Sessions::Factory.default
    end

    before do
      Mongoid::Config.sessions = config
      Mongoid::Config.databases = database_config
      Mongoid::Threaded.sessions[:default] = session
    end

    context "when overriding the default with store_in" do

      before do
        Band.store_in(collection: "artists")
      end

      after do
        Band.storage_options = nil
        Band.send(:remove_instance_variable, :@collection_name)
      end

      let(:band) do
        Band.new
      end

      it "returns the collection for the model" do
        band.collection.should be_a(Moped::Collection)
      end

      it "sets the correct collection name" do
        band.collection.name.should eq(:artists)
      end

      context "when accessing from the class level" do

        it "returns the collection for the model" do
          Band.collection.should be_a(Moped::Collection)
        end

        it "sets the correct collection name" do
          Band.collection.name.should eq(:artists)
        end
      end

      context "when safety options exist" do

        context "when the options are from the current thread" do

          before do
            Band.safely(w: 3)
          end

          it "clears the options from the current thread" do
            Band.collection
            Mongoid::Safety.options.should be_false
          end

          it "returns the collection" do
            Band.collection.should be_a(Moped::Collection)
          end
        end
      end
    end

    context "when not overriding the default" do

      after do
        Band.send(:remove_instance_variable, :@collection_name)
      end

      let(:band) do
        Band.new
      end

      it "returns the collection for the model" do
        band.collection.should be_a(Moped::Collection)
      end

      it "sets the correct collection name" do
        band.collection.name.should eq(:bands)
      end

      context "when accessing from the class level" do

        it "returns the collection for the model" do
          Band.collection.should be_a(Moped::Collection)
        end

        it "sets the correct collection name" do
          Band.collection.name.should eq(:bands)
        end
      end
    end
  end

  describe "#collection_name" do

    context "when overriding the default with store_in" do

      before do
        Band.store_in(collection: "artists")
      end

      after do
        Band.storage_options = nil
        Band.send(:remove_instance_variable, :@collection_name)
      end

      let(:band) do
        Band.new
      end

      it "returns the overridden value" do
        band.collection_name.should eq(:artists)
      end

      context "when accessing from the class level" do

        it "returns the overridden value" do
          Band.collection_name.should eq(:artists)
        end
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

    context "when overriding the default with store_in" do

      let(:config) do
        { secondary: { hosts: [ "localhost:27017" ] }}
      end

      let(:database_config) do
        { default: { name: database_id }}
      end

      let(:session) do
        Mongoid::Sessions::Factory.create(:secondary)
      end

      before do
        Mongoid::Config.sessions = config
        Mongoid::Config.databases = database_config
        Mongoid::Threaded.sessions[:secondary] = session
        Band.store_in(session: "secondary")
      end

      after do
        Band.storage_options = nil
      end

      let(:band) do
        Band.new
      end

      it "returns the overridden session" do
        band.mongo_session.should eq(session)
      end

      context "when accessing from the class level" do

        it "returns the overridden session" do
          Band.mongo_session.should eq(session)
        end
      end
    end

    context "when no default is overridden" do

      let(:config) do
        { default: { hosts: [ "localhost:27017" ] }}
      end

      let(:database_config) do
        { default: { name: database_id }}
      end

      let(:session) do
        Mongoid::Sessions::Factory.default
      end

      before do
        Mongoid::Config.sessions = config
        Mongoid::Config.databases = database_config
        Mongoid::Threaded.sessions[:default] = session
      end

      let(:band) do
        Band.new
      end

      it "returns the default session" do
        band.mongo_session.should eq(session)
      end

      context "when accessing from the class level" do

        it "returns the default session" do
          Band.mongo_session.should eq(session)
        end
      end
    end
  end
end
