require "spec_helper"
require "rails/generators/mongoid/model/model_generator"

describe Mongoid::Generators::ModelGenerator do

  destination File.expand_path("../../../../../../tmp", __FILE__)

  before do
    Rails.stubs(:application).returns(mock)
    prepare_destination
  end

  context "when generating a company model" do

    let(:model) do
      file("app/models/company.rb")
    end

    context "when providing no arguments" do

      before do
        run_generator %w(company)
      end

      it "generates the file" do
        model.should exist
      end

      it "defines the class" do
        model.should contain("class Company")
      end

      it "includes Mongoid::Document" do
        model.should contain("include Mongoid::Document")
      end
    end

    context "when providing field arguments" do

      before do
        run_generator %w(company name:string)
      end

      it "adds the fields to the model" do
        model.should contain("field :name, type: String")
      end
    end

    context "when including timestamps" do

      before do
        run_generator %w(company --timestamps)
      end

      it "adds the timestamping module" do
        model.should contain("include Mongoid::Timestamps")
      end
    end

    context "when providing a superclass" do

      before do
        run_generator %w(company --parent organization)
      end

      it "adds the superclass to the model" do
        model.should contain("class Company < Organization")
      end

      it "does not include the document module" do
        model.should_not contain("include Mongoid::Document")
      end
    end

    context "when including versioning" do

      before do
        run_generator %w(company --versioning)
      end

      it "adds the versioning module" do
        model.should contain("include Mongoid::Versioning")
      end
    end
  end
end
