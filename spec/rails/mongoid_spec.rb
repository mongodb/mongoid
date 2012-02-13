require "spec_helper"

describe "Rails::Mongoid" do

  before(:all) do
    require "rails/mongoid"
  end

  describe ".create_indexes" do
    let(:pattern) { "spec/app/models/**/*.rb" }
    let(:logger) { stub }
    let(:klass) { Person }
    let(:model_paths) { [ "spec/app/models/person.rb" ] }
    let(:indexes) { Rails::Mongoid.create_indexes(pattern) }

    before do
      Dir.expects(:glob).with(pattern).returns(model_paths).once
      Logger.expects(:new).returns(logger)
    end

    context "with ordinary Rails models" do
      it "creates the indexes for the models" do
        klass.expects(:create_indexes).once
        logger.expects(:info).once
        indexes
      end
    end

    context "with a model without indexes" do
      let(:model_paths) { [ "spec/app/models/account.rb" ] }
      let(:klass) { Account }

      it "does nothing" do
        klass.expects(:create_indexes).never
        indexes
      end
    end

    context "when an exception is raised" do
      it "is not swallowed" do
        Rails::Mongoid.expects(:determine_model).returns(klass)
        klass.expects(:create_indexes).raises(Mongo::MongoArgumentError)
        expect { indexes }.to raise_error(Mongo::MongoArgumentError)
      end
    end

    context "when index is defined on embedded model" do
      let(:klass) { Address }
      let(:model_paths) { [ "spec/app/models/address.rb" ] }

      before do
        klass.index_options = { :city => {} }
      end

      it "does nothing, but logging" do
        klass.expects(:create_indexes).never
        logger.expects(:info).once
        indexes
      end
    end
  end

  describe ".determine_model" do
    let(:logger) { stub }
    let(:klass) { Person }
    let(:file) { "app/models/person.rb" }
    let(:model) { Rails::Mongoid.send(:determine_model, file, logger) }

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
      let(:file) { nil }

      it "returns nil" do
        model.should be_nil
      end
    end

    context "when logger is nil" do
      let(:logger) { nil }

      it "returns nil" do
        model.should be_nil
      end
    end

    context "when path is invalid" do
      let(:file) { "fu/bar.rb" }

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
        let(:klass) { Twitter::Follow }
        let(:file) { "app/models/follow.rb" }

        it "raises NameError" do
          expect { model.should eq(klass) }.to raise_error(NameError)
        end
      end
    end

    context "when file is in a subdir" do
      context "with file from normal model" do
        let(:file) { "app/models/fu/person.rb" }

        it "returns klass" do
          model.should eq(klass)
        end
      end

      context "when file is in a module" do
        let(:klass) { Twitter::Follow }
        let(:file) { "app/models/twitter/follow.rb" }

        it "returns klass in module" do
          model.should eq(klass)
        end
      end

      context "when file is in two modules" do
        let(:klass) { Twitter::List::Tweet }
        let(:file) { "app/models/twitter/list/tweet.rb" }

        it "returns klass in module" do
          model.should eq(klass)
        end
      end
    end

    context "with models present in Rails engines" do
      let(:file) { "/gem_path/engines/some_engine_gem/app/models/person.rb" }
      let(:klass) { Person }

      it "requires the models by base name from the engine's app/models dir" do
        model.should eq(klass)
      end
    end
  end

  describe ".preload_models" do

    let(:app) do
      stub(:config => config)
    end

    let(:config) do
      stub(:paths => paths)
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
        Dir.stubs(:glob).with("/rails/root/app/models/**/*.rb").returns(files)
      end

      it "does not load any models" do
        Rails::Mongoid.expects(:load_model).never
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
          Dir.expects(:glob).with("/rails/root/app/models/**/*.rb").returns(files)
        end

        it "requires the models by basename" do
          Rails::Mongoid.expects(:load_model).with("address")
          Rails::Mongoid.expects(:load_model).with("user")
          Rails::Mongoid.preload_models(app)
        end
      end

      context "when models exist in subdirectories" do

        let(:files) do
          [ "/rails/root/app/models/mongoid/behaviour.rb" ]
        end

        before do
          Dir.expects(:glob).with("/rails/root/app/models/**/*.rb").returns(files)
        end

        it "requires the models by subdirectory and basename" do
          Rails::Mongoid.expects(:load_model).with("mongoid/behaviour")
          Rails::Mongoid.preload_models(app)
        end
      end
    end
  end

  describe ".load_models" do

    let(:app) do
      stub(:config => config)
    end

    let(:config) do
      stub(:paths => paths)
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
        Dir.stubs(:glob).with("/rails/root/app/models/**/*.rb").returns(files)
      end

      it "loads all models" do
        Rails::Mongoid.expects(:load_model).with("address")
        Rails::Mongoid.expects(:load_model).with("user")
        Rails::Mongoid.load_models(app)
      end
    end
  end
end
