require "spec_helper"
require "rails/generators/mongoid/config/config_generator"

describe Mongoid::Generators::ConfigGenerator do

  destination File.expand_path("../../../../../../tmp", __FILE__)

  before do
    prepare_destination
  end

  context "when not providing any arguments" do

    before do
      run_generator
    end

    context "when generating config/mongoid.yml" do

      let!(:config) do
        file("config/mongoid.yml")
      end

      it "generates the config" do
        config.should exist
      end

      it "generates with a default database name" do
        config.should contain("name: my_app_development")
      end
    end
  end

  context "when not providing arguments" do

    before do
      run_generator %w(my_database)
    end

    context "when generating config/mongoid.yml" do

      let!(:config) do
        file("config/mongoid.yml")
      end

      it "generates the config" do
        config.should exist
      end

      it "generates with the provided database name" do
        config.should contain("name: my_database_development")
      end
    end
  end
end
