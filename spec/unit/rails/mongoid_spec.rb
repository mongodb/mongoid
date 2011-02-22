require "spec_helper"

describe "Rails::Mongoid" do

  before(:all) do
    require "rails/mongoid"
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

    context "when load models config is false" do

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
        Rails::Mongoid.load_models(app)
      end
    end

    context "when load models config is true" do

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
          Rails::Mongoid.load_models(app)
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
          Rails::Mongoid.load_models(app)
        end
      end
    end
  end
end
