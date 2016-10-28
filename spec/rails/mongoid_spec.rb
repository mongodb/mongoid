require "spec_helper"

describe "Rails::Mongoid" do

  before(:all) do
    require "rails/mongoid"
    ::Mongoid.models.delete_if do |model|
      ![ User, Account, Address, AddressNumber ].include?(model)
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
      double('[]' => path)
    end

    let(:path) do
      double(expanded: [ "/rails/root/app/models" ])
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
      double('[]' => path)
    end

    let(:path) do
      double(expanded: [ "/rails/root/app/models" ])
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
        Mongoid.preload_models = ["user", "AddressNumber"]
      end

      it "loads selected models only" do
        allow(Dir).to receive(:glob).with("/rails/root/app/models/**/*.rb").and_return(files)
        expect(Rails::Mongoid).to receive(:load_model).with("user")
        expect(Rails::Mongoid).to receive(:load_model).with("address_number")
        expect(Rails::Mongoid).to receive(:load_model).with("address").never
        Rails::Mongoid.load_models(app)
      end
    end
  end
end
