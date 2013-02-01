require "spec_helper"

describe "Rails::Mongoid" do

  before(:all) do
    require "rails/mongoid"
  end

  describe ".create_indexes" do

    let(:pattern) do
      "spec/app/models/**/*.rb"
    end

    let(:logger) do
      stub
    end

    let(:klass) do
      User
    end

    let(:model_paths) do
      [ "spec/app/models/user.rb" ]
    end

    let(:indexes) do
      Rails::Mongoid.create_indexes(pattern)
    end

    before do
      Dir.should_receive(:glob).once.with(pattern).and_return(model_paths)
    end

    context "with ordinary Rails models" do

      it "creates the indexes for the models" do
        klass.should_receive(:create_indexes).once
        indexes
      end
    end

    context "with a model without indexes" do

      let(:model_paths) do
        [ "spec/app/models/account.rb" ]
      end

      let(:klass) do
        Account
      end

      it "does nothing" do
        klass.should_receive(:create_indexes).never
        indexes
      end
    end

    context "when an exception is raised" do

      it "is not swallowed" do
        Rails::Mongoid.should_receive(:determine_model).and_return(klass)
        klass.should_receive(:create_indexes).and_raise(ArgumentError)
        expect { indexes }.to raise_error(ArgumentError)
      end
    end

    context "when index is defined on embedded model" do

      let(:klass) do
        Address
      end

      let(:model_paths) do
        [ "spec/app/models/address.rb" ]
      end

      before do
        klass.index_options = { city: {} }
      end

      it "does nothing, but logging" do
        klass.should_receive(:create_indexes).never
        indexes
      end
    end
  end

  describe ".remove_indexes" do

    let(:pattern) do
      "spec/app/models/**/*.rb"
    end

    let(:logger) do
      stub
    end

    let(:klass) do
      User
    end

    let(:model_paths) do
      [ "spec/app/models/user.rb" ]
    end

    before do
      Dir.should_receive(:glob).with(pattern).exactly(2).times.and_return(model_paths)
    end

    let(:indexes) do
      klass.collection.indexes
    end

    before :each do
      Rails::Mongoid.create_indexes(pattern)
      Rails::Mongoid.remove_indexes(pattern)
    end

    it "removes indexes from klass" do
      indexes.reject{ |doc| doc["name"] == "_id_" }.should be_empty
    end

    it "leaves _id index untouched" do
      indexes.select{ |doc| doc["name"] == "_id_" }.should_not be_empty
    end
  end

  describe ".models" do

    let(:pattern) do
      "spec/app/models/**/*.rb"
    end

    let(:logger) do
      stub
    end

    let(:klass) do
      User
    end

    let(:model_paths) do
      [ "spec/app/models/user.rb" ]
    end

    let(:models) do
      Rails::Mongoid.models(pattern)
    end

    before do
      Dir.should_receive(:glob).with(pattern).once.and_return(model_paths)
    end

    it "returns models which files matching the pattern" do
      models.should eq([klass])
    end
  end

  describe ".determine_model" do

    let(:logger) do
      stub
    end

    let(:klass) do
      User
    end

    let(:file) do
      "app/models/user.rb"
    end

    let(:model) do
      Rails::Mongoid.send(:determine_model, file, logger)
    end

    class EasyURI
    end

    module Twitter
      class Follow
        include Mongoid::Document
      end

      module List
        class Tweet
          include Mongoid::Document
        end
      end
    end

    context "when file is nil" do

      let(:file) do
        nil
      end

      it "returns nil" do
        model.should be_nil
      end
    end

    context "when logger is nil" do

      let(:logger) do
        nil
      end

      it "returns nil" do
        model.should be_nil
      end
    end

    context "when path is invalid" do

      let(:file) do
        "fu/bar.rb"
      end

      it "returns nil" do
        model.should be_nil
      end
    end

    context "when file cannot be constantize" do

      let(:file) do
        "app/models/easy_uri.rb"
      end

      before do
        logger.should_receive(:info)
      end

      it "returns nil" do
        model.should be_nil
      end
    end

    context "when file is not in a subdir" do

      context "when file is from normal model" do

        it "returns klass" do
          model.should eq(klass)
        end
      end

      context "when file is in a module" do

        let(:klass) do
          Twitter::Follow
        end

        let(:file) do
          "app/models/follow.rb"
        end

        it "logs the class without an error" do
          logger.should_receive(:info)
          expect { model.should eq(klass) }.not_to raise_error(NameError)
        end
      end
    end

    context "when file is in a subdir" do

      context "with file from normal model" do

        let(:file) do
          "app/models/fu/user.rb"
        end

        it "returns klass" do
          logger.should_receive(:info)
          model.should eq(klass)
        end
      end

      context "when file is in a module" do

        let(:klass) do
          Twitter::Follow
        end

        let(:file) do
          "app/models/twitter/follow.rb"
        end

        it "returns klass in module" do
          model.should eq(klass)
        end
      end

      context "when file is in two modules" do

        let(:klass) do
          Twitter::List::Tweet
        end

        let(:file) do
          "app/models/twitter/list/tweet.rb"
        end

        it "returns klass in module" do
          model.should eq(klass)
        end
      end
    end

    context "with models present in Rails engines" do

      let(:file) do
        "/gem_path/engines/some_engine_gem/app/models/user.rb"
      end

      let(:klass) do
        User
      end

      it "requires the models by base name from the engine's app/models dir" do
        model.should eq(klass)
      end
    end
  end

  describe ".preload_models" do

    let(:app) do
      stub(config: config)
    end

    let(:config) do
      stub(paths: paths)
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
        Dir.stub(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
      end

      it "does not load any models" do
        Rails::Mongoid.should_receive(:load_model).never
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
          Dir.should_receive(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
        end

        it "requires the models by basename" do
          Rails::Mongoid.should_receive(:load_model).with("address")
          Rails::Mongoid.should_receive(:load_model).with("user")
          Rails::Mongoid.preload_models(app)
        end
      end

      context "when models exist in subdirectories" do

        let(:files) do
          [ "/rails/root/app/models/mongoid/behaviour.rb" ]
        end

        before do
          Dir.should_receive(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
        end

        it "requires the models by subdirectory and basename" do
          Rails::Mongoid.should_receive(:load_model).with("mongoid/behaviour")
          Rails::Mongoid.preload_models(app)
        end
      end
    end
  end

  describe ".load_models" do

    let(:app) do
      stub(config: config)
    end

    let(:config) do
      stub(paths: paths)
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
        Dir.stub(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
      end

      it "loads all models" do
        Rails::Mongoid.should_receive(:load_model).with("address")
        Rails::Mongoid.should_receive(:load_model).with("user")
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
        Dir.stub(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
      end

      it "loads selected models only" do
        Rails::Mongoid.should_receive(:load_model).with("user")
        Rails::Mongoid.should_receive(:load_model).with("address").never
        Rails::Mongoid.load_models(app)
      end
    end
  end
end
