# frozen_string_literal: true
# rubocop:todo all

require "ostruct"
require "spec_helper"
require "support/feature_sandbox"

describe Mongoid::Loadable do
  let(:model_root) do
    File.absolute_path(
      File.join(
        File.dirname(__FILE__),
        "../support/models/sandbox"
      ))
  end

  let(:app_models_root) { File.join(model_root, "app/models") }
  let(:lib_models_root) { File.join(model_root, "lib/models") }

  describe "#model_paths" do
    # reset model_paths to the default value
    before { Mongoid.model_paths = nil }

    context "when Rails is defined" do
      around do |example|
        FeatureSandbox.quarantine do
          require "support/rails_mock"
          require "rails/mongoid"
          example.run
        end
      end

      it "should return Rails' \"app/models\" paths" do
        expect(Mongoid.model_paths).to be == %w( app/models )
      end
    end

    context "when Rails is not defined" do
      it "should return Mongoid's default model paths" do
        expect(Mongoid.model_paths).to be == %w( ./app/models ./lib/models )
      end
    end

    context "when explicitly set" do
      before { Mongoid.model_paths = %w( /infra/models ) }
      
      it "should return the given value" do
        expect(Mongoid.model_paths).to be == %w( /infra/models )
      end
    end
  end

  describe "#load_models" do
    around :each do |example|
      FeatureSandbox.quarantine do
        Mongoid.model_paths = nil
        example.run
      end
    end

    context "when using default paths" do
      around(:each) do |example|
        $LOAD_PATH.concat [ app_models_root, lib_models_root ]

        Dir.chdir(model_root) do
          Mongoid.load_models
          example.run
        end
      end

      it "should find models in the default paths" do
        expect(defined?(AppModelsMessage)).to be == "constant"
        expect(defined?(LibModelsMessage)).to be == "constant"
        expect(defined?(SandboxMessage)).to be_nil
      end
    end

    context "when using custom model_paths" do
      before do
        Mongoid.model_paths = [ app_models_root ]
        $LOAD_PATH.concat [ app_models_root ]
        Mongoid.load_models
      end

      it "should find models in the specified paths" do
        expect(defined?(AppModelsMessage)).to be == "constant"
        expect(defined?(LibModelsMessage)).to be_nil
        expect(defined?(SandboxMessage)).to be_nil
      end
    end

    context "when passing paths directly" do
      before do
        $LOAD_PATH.concat [ model_root ]
        Mongoid.load_models([ model_root ])
      end

      it "should find models in the specified paths" do
        expect(defined?(AppModelsMessage)).to be == "constant"
        expect(defined?(LibModelsMessage)).to be == "constant"
        expect(defined?(SandboxMessage)).to be == "constant"
        expect(defined?(SandboxComment)).to be == "constant"
      end
    end
  end
end

module Mongoid::Loadable::RailsApplication
  attr_accessor :application
end
