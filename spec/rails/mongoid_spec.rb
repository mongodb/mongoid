require "spec_helper"

describe "Rails::Mongoid" do

  before(:all) do
    require "rails/mongoid"
    ::Mongoid.models.delete_if do |model|
      ![ User, Account, Address ].include?(model)
    end
  end

  describe ".create_indexes" do

    let(:logger) do
      double
    end

    let!(:klass) do
      User
    end

    let(:model_paths) do
      [ "spec/app/models/user.rb" ]
    end

    let(:indexes) do
      Rails::Mongoid.create_indexes
    end

    context "with ordinary Rails models" do

      it "creates the indexes for the models" do
        expect(klass).to receive(:create_indexes).once
        indexes
      end
    end

    context "with a model without indexes" do

      let(:klass) do
        Account
      end

      it "does nothing" do
        expect(klass).to receive(:create_indexes).never
        indexes
      end
    end

    context "when an exception is raised" do

      it "is not swallowed" do
        expect(klass).to receive(:create_indexes).and_raise(ArgumentError)
        expect { indexes }.to raise_error(ArgumentError)
      end
    end

    context "when index is defined on embedded model" do

      let!(:klass) do
        Address
      end

      before do
        klass.index(street: 1)
      end

      it "does nothing, but logging" do
        expect(klass).to receive(:create_indexes).never
        indexes
      end
    end
  end

  describe ".undefined_indexes" do

    before(:each) do
      Rails::Mongoid.create_indexes
    end

    let(:indexes) do
      Rails::Mongoid.undefined_indexes
    end

    it "returns the removed indexes" do
      expect(indexes).to be_empty
    end

    context "with extra index on model collection" do

      before(:each) do
        User.collection.indexes.create(account_expires: 1)
      end

      let(:names) do
        indexes[User].map{ |index| index['name'] }
      end

      it "should have single index returned" do
        expect(names).to eq(['account_expires_1'])
      end
    end
  end

  describe ".remove_undefined_indexes" do

    let(:logger) do
      double
    end

    let(:indexes) do
      User.collection.indexes
    end

    before(:each) do
      Rails::Mongoid.create_indexes
      indexes.create(account_expires: 1)
      Rails::Mongoid.remove_undefined_indexes
    end

    let(:removed_indexes) do
      Rails::Mongoid.undefined_indexes
    end

    it "returns the removed indexes" do
      expect(removed_indexes).to be_empty
    end
  end

  describe ".remove_indexes" do

    let(:logger) do
      double
    end

    let!(:klass) do
      User
    end

    let(:indexes) do
      klass.collection.indexes
    end

    before :each do
      Rails::Mongoid.create_indexes
      Rails::Mongoid.remove_indexes
    end

    it "removes indexes from klass" do
      expect(indexes.reject{ |doc| doc["name"] == "_id_" }).to be_empty
    end

    it "leaves _id index untouched" do
      expect(indexes.select{ |doc| doc["name"] == "_id_" }).to_not be_empty
    end
  end

  describe ".preload_models" do

    let(:app) do
      double(config: config)
    end

    let(:config) do
      double(paths: paths)
    end

    let(:paths) do
      { "app/models" => [ "/rails/root/app/models" ] }
    end

    context "when preload models config is false" do

      let(:files) do
        [
          "/rails/root/app/models/user.rb",
          "/rails/root/app/models/address.rb"
        ]
      end

      before(:all) do
        Mongoid.preload_models = false
      end

      it "does not load any models" do
        allow(Dir).to receive(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
        expect(Rails::Mongoid).to receive(:load_model).never
        Rails::Mongoid.preload_models(app)
      end
    end

    context "when preload models config is true" do

      before(:all) do
        Mongoid.preload_models = true
      end

      context "when all models are in the models directory" do

        let(:files) do
          [
            "/rails/root/app/models/user.rb",
            "/rails/root/app/models/address.rb"
          ]
        end

        before do
          expect(Dir).to receive(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
        end

        it "requires the models by basename" do
          expect(Rails::Mongoid).to receive(:load_model).with("address")
          expect(Rails::Mongoid).to receive(:load_model).with("user")
          Rails::Mongoid.preload_models(app)
        end
      end

      context "when models exist in subdirectories" do

        let(:files) do
          [ "/rails/root/app/models/mongoid/behaviour.rb" ]
        end

        before do
          expect(Dir).to receive(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
        end

        it "requires the models by subdirectory and basename" do
          expect(Rails::Mongoid).to receive(:load_model).with("mongoid/behaviour")
          Rails::Mongoid.preload_models(app)
        end
      end
    end
  end

  describe ".load_models" do

    let(:app) do
      double(config: config)
    end

    let(:config) do
      double(paths: paths)
    end

    let(:paths) do
      { "app/models" => [ "/rails/root/app/models" ] }
    end

    context "even when preload models config is false" do

      let(:files) do
        [
          "/rails/root/app/models/user.rb",
          "/rails/root/app/models/address.rb"
        ]
      end

      before(:all) do
        Mongoid.preload_models = false
      end

      it "loads all models" do
        allow(Dir).to receive(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
        expect(Rails::Mongoid).to receive(:load_model).with("address")
        expect(Rails::Mongoid).to receive(:load_model).with("user")
        Rails::Mongoid.load_models(app)
      end
    end

    context "when list of models to load was configured" do

      let(:files) do
        [
          "/rails/root/app/models/user.rb",
          "/rails/root/app/models/address.rb"
        ]
      end

      before(:all) do
        Mongoid.preload_models = ["user"]
      end

      it "loads selected models only" do
        allow(Dir).to receive(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
        expect(Rails::Mongoid).to receive(:load_model).with("user")
        expect(Rails::Mongoid).to receive(:load_model).with("address").never
        Rails::Mongoid.load_models(app)
      end
    end
  end
end
