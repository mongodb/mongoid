require "spec_helper"

describe "Rails::Mongoid" do

  before(:all) do
    require "rails/mongoid"
  end

  describe ".create_indexes" do

    let(:model_paths) do
      Dir.glob("spec/models/**/*.rb")
    end

    let(:models) do
      [].tap do |documents|
        model_paths.each do |file|
          model_path = file[0..-4].split('/')[2..-1]
          begin
            klass = model_path.map { |path| path.camelize }.join('::').constantize
            if klass.ancestors.include?(Mongoid::Document) && !klass.embedded
              documents << klass
            end
          rescue => e
          end
        end
      end
    end

    before do
      models.each do |klass|
        klass.expects(:create_indexes).once
      end
    end

    it "creates the indexes for each model" do
      Rails::Mongoid.create_indexes("spec/models/**/*.rb")
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
