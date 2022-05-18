# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Config::Environment do

  around do |example|
    if defined?(Rails)
      SavedRails = Rails
      example.run
      Object.send(:remove_const, :Rails) if defined?(Rails)
      Rails = SavedRails
      Object.send(:remove_const, :SavedRails)
    else
      example.run
      if defined?(Rails)
        Object.send(:remove_const, :Rails)
      end
    end
  end

  describe "#env_name" do

    context "when using rails" do

      context "when an environment exists" do

        before do
          module Rails
            class << self
              def env; "production"; end
            end
          end
        end

        it "returns the rails environment" do
          expect(described_class.env_name).to eq("production")
        end
      end
    end

    context "when using sinatra" do

      before do
        Object.send(:remove_const, :Rails) if defined?(Rails)

        module Sinatra
          module Base
            extend self
            def environment; :staging; end
          end
        end
      end

      after do
        Object.send(:remove_const, :Sinatra)
      end

      it "returns the sinatra environment" do
        expect(described_class.env_name).to eq("staging")
      end
    end

    context "when the rack env variable is defined" do

      before do
        Object.send(:remove_const, :Rails) if defined?(Rails)
        ENV["RACK_ENV"] = "acceptance"
      end

      after do
        ENV["RACK_ENV"] = nil
      end

      it "returns the rack environment" do
        expect(described_class.env_name).to eq("acceptance")
      end
    end

    context "when no environment information is found" do

      before do
        Object.send(:remove_const, :Rails) if defined?(Rails)
      end

      it "raises an error" do
        expect { described_class.env_name }.to raise_error(
          Mongoid::Errors::NoEnvironment
        )
      end
    end
  end

  describe "#load_yaml" do
    let(:path) { 'mongoid.yml' }
    let(:environment) {}
    before { allow(Rails).to receive('env').and_return('test') }

    subject { described_class.load_yaml(path, environment) }

    context 'when file not found' do
      let(:path) { 'not/a/valid/path'}

      it { expect { subject }.to raise_error(Errno::ENOENT) }
    end

    context 'when file found' do
      before do
        allow(File).to receive(:read).with('mongoid.yml').and_return(file_contents)
      end

      let(:file_contents) do
        <<~FILE
          test:
            clients: ['test']
          development:
            clients: ['dev']
        FILE
      end

      context 'when file cannot be parsed as YAML' do
        let(:file_contents) { "*\nbad:%123abc" }

        it { expect { subject }.to raise_error(Psych::SyntaxError) }
      end

      context 'when file contains ERB errors' do
        let(:file_contents) { '<%= foo %>' }

        it { expect { subject }.to raise_error(NameError) }
      end

      context 'when file is empty' do
        let(:file_contents) { '' }

        it { expect { subject }.to raise_error(Mongoid::Errors::EmptyConfigFile) }
      end

      context 'when file does not contain a YAML Hash object' do
        let(:file_contents) { '["this", "is", "an", "array"]' }

        it { expect { subject }.to raise_error(Mongoid::Errors::InvalidConfigFile) }
      end

      context 'when environment not specified' do
        it 'uses the rails environment' do
          is_expected.to eq("clients"=>["test"])
        end
      end

      context 'when environment is specified' do
        let(:environment) { 'development' }

        it 'uses the specified environment' do
          is_expected.to eq("clients"=>["dev"])
        end
      end

      context 'when environment is missing' do
        let(:environment) { 'staging' }

        it { is_expected.to be_nil }
      end
    end

    context 'when configuration includes schema map' do
      paths = Dir.glob(File.join(File.dirname(__FILE__), '../../support/schema_maps/*.json'))

      if paths.empty?
        raise "Expected to find some schema maps"
      end

      before do
        allow(File).to receive(:read).with('mongoid.yml').and_return(file_contents)
      end

      let(:file_contents) do
        <<~FILE
          test:
            clients:
              default:
                database: mongoid_test
                hosts: [localhost]
                options:
                  auto_encryption_options:
                    schema_map: #{schema_map.to_yaml.sub(/\A---/, '').gsub(/\n/, "\n" + ' '*100)}
        FILE
      end

      paths.each do |path|
        context File.basename(path) do
          let(:schema_map) do
            BSON::ExtJSON.parse(File.read(path))
          end

          it 'loads successfully' do
            subject.should be_a(Hash)
            subject.fetch('clients').fetch('default').fetch('options').fetch('auto_encryption_options').fetch('schema_map').should be_a(Hash)
          end
        end
      end
    end
  end
end
