# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Config do

  after(:all) do
    if defined?(RailsTemp)
      Rails = RailsTemp
    end
  end

  after do
    Mongoid.configure do |config|
      config.load_configuration(CONFIG)
    end
  end

  describe "#configured?" do

    after do
      described_class.connect_to(database_id, read: :primary)
    end

    context "when a default client config exists" do

      context "when a default database is configured" do

        let(:config) do
          {
            default: {
              database: database_id,
              hosts: [ "127.0.0.1:27017" ]
            }
          }
        end

        before do
          described_class.send(:clients=, config)
        end

        it "returns true" do
          expect(described_class).to be_configured
        end
      end
    end

    context "when no default client config exists" do

      before do
        described_class.clients.clear
      end

      it "returns false" do
        expect(described_class).to_not be_configured
      end
    end
  end

  describe "#destructive_fields" do

    Mongoid::Composable.prohibited_methods.each do |method|

      it "contains #{method}" do
        expect(described_class.destructive_fields).to include(method)
      end
    end
  end

  context "when the log level is not set in the configuration" do

    before do
      if defined?(Rails)
        RailsTemp = Rails unless defined?(RailsTemp)
        Object.send(:remove_const, :Rails)
      end

      Mongoid.configure do |config|
        config.load_configuration(CONFIG)
      end
    end

    it "sets the Mongoid logger level to the default" do
      expect(Mongoid.logger.level).to eq(Logger::INFO)
    end

    it "sets the Mongo driver logger level to the default" do
      expect(Mongo::Logger.logger.level).to eq(Logger::INFO)
    end
  end

  context 'when background_indexing option' do
    context 'is not set in the config' do
      it 'sets the value to false by default' do
        Mongoid::Config.reset
        configuration = CONFIG.merge(options: {})

        Mongoid.configure { |config| config.load_configuration(configuration) }

        expect(Mongoid::Config.background_indexing).to be(false)
      end
    end

    context 'is set in the config' do
      it 'sets the value' do
        Mongoid::Config.reset
        configuration = CONFIG.merge(options: {background_indexing: true})

        Mongoid.configure { |config| config.load_configuration(configuration) }

        expect(Mongoid::Config.background_indexing).to be(true)
      end
    end
  end

  context 'when the belongs_to_required_by_default option is not set in the config' do

    before do
      Mongoid::Config.reset
      Mongoid.configure do |config|
        config.load_configuration(clients: CONFIG[:clients])
      end
    end

    it 'sets the Mongoid.belongs_to_required_by_default value to true' do
      expect(Mongoid.belongs_to_required_by_default).to be(true)
    end
  end

  context 'when the belongs_to_required_by_default option is set in the config' do

    before do
      Mongoid.configure do |config|
        config.load_configuration(conf)
      end
    end

    context 'when the value is set to true' do

      let(:conf) do
        CONFIG.merge(options: { belongs_to_required_by_default: true })
      end

      it 'sets the Mongoid.belongs_to_required_by_default value to true' do
        expect(Mongoid.belongs_to_required_by_default).to be(true)
      end
    end

    context 'when the value is set to false' do

      let(:conf) do
        CONFIG.merge(options: { belongs_to_required_by_default: false })
      end

      before do
        Mongoid::Config.reset
        Mongoid.configure do |config|
          config.load_configuration(conf)
        end
      end

      it 'sets the Mongoid.belongs_to_required_by_default value to false' do
        expect(Mongoid.belongs_to_required_by_default).to be(false)
      end
    end
  end

  context 'when the app_name is set in the config' do

    let(:conf) do
      CONFIG.merge(options: { app_name: 'admin-reporting' })
    end

    before do
      Mongoid.configure do |config|
        config.load_configuration(conf)
      end
    end

    it 'sets the Mongoid.app_name to the provided value' do
      expect(Mongoid.app_name).to eq('admin-reporting')
    end
  end

  context 'when the app_name is not set in the config' do

    before do
      Mongoid::Config.reset
      Mongoid.configure do |config|
        config.load_configuration(CONFIG)
      end
    end

    it 'does not set the Mongoid.app_name option' do
      expect(Mongoid.app_name).to be_nil
    end
  end

  describe "#load!" do

    before(:all) do
      if defined?(Rails)
        RailsTemp = Rails
        Object.send(:remove_const, :Rails)
      end
    end

    let(:file) do
      File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
    end

    context "when existing clients exist in the configuration" do

      let(:client) do
        Mongo::Client.new([ "127.0.0.1:27017" ])
      end

      before do
        Mongoid::Clients.clients[:test] = client
        described_class.load!(file, :test)
      end

      after do
        client.close
      end

      it "clears the previous clients" do
        expect(Mongoid::Clients.clients[:test]).to be_nil
      end
    end

    context "when the log level is set in the configuration" do

      before do
        described_class.load!(file, :test)
      end

      it "sets the Mongoid logger level" do
        expect(Mongoid.logger.level).to eq(Logger::WARN)
      end

      it "sets the Mongo driver logger level" do
        expect(Mongo::Logger.logger.level).to eq(Logger::WARN)
      end

      context "when in a Rails environment" do

        before do
          module Rails
            def self.logger
              ::Logger.new($stdout)
            end
          end
          Mongoid.logger = Rails.logger
          described_class.load!(file, :test)
        end

        after do
          if defined?(Rails)
            RailsTemp = Rails unless defined?(RailsTemp)
            Object.send(:remove_const, :Rails)
          end
        end

        it "keeps the Mongoid logger level the same as the Rails logger" do
          expect(Mongoid.logger.level).to eq(Rails.logger.level)
          expect(Mongoid.logger.level).not_to eq(Mongoid::Config.log_level)
        end

        it "sets the Mongo driver logger level to Mongoid's logger level" do
          expect(Mongo::Logger.logger.level).to eq(Mongoid.logger.level)
        end
      end
    end

    context "when provided an environment" do

      before do
        described_class.load!(file, :test)
      end

      after do
        described_class.reset
      end

      it "sets the include root in json option" do
        expect(described_class.include_root_in_json).to be false
      end

      it "sets the include type with serialization option" do
        expect(described_class.include_type_for_serialization).to be false
      end

      it "sets the scope overwrite option" do
        expect(described_class.scope_overwrite_exception).to be false
      end

      it "sets the preload models option" do
        expect(described_class.preload_models).to be false
      end

      it "sets the raise not found error option" do
        expect(described_class.raise_not_found_error).to be true
      end

      it "sets the use activesupport time zone option" do
        expect(described_class.use_activesupport_time_zone).to be true
      end

      it "sets the use utc option" do
        expect(described_class.use_utc).to be false
      end

      it "sets the join_contexts default option" do
        expect(described_class.join_contexts).to be false
      end
    end

    context "when the rack environment is set" do

      before do
        ENV["RACK_ENV"] = "test"
      end

      after do
        ENV["RACK_ENV"] = nil
        described_class.reset
      end

      context "when mongoid options are provided" do

        before do
          described_class.load!(file)
        end

        it "sets the include root in json option" do
          expect(described_class.include_root_in_json).to be false
        end

        it "sets the include type with serialization option" do
          expect(described_class.include_type_for_serialization).to be false
        end

        it "sets the scope overwrite option" do
          expect(described_class.scope_overwrite_exception).to be false
        end

        it "sets the preload models option" do
          expect(described_class.preload_models).to be false
        end

        it "sets the raise not found error option" do
          expect(described_class.raise_not_found_error).to be true
        end

        it "sets the use activesupport time zone option" do
          expect(described_class.use_activesupport_time_zone).to be true
        end

        it "sets the use utc option" do
          expect(described_class.use_utc).to be false
        end

        it "sets the join_contexts default option" do
          expect(described_class.join_contexts).to be false
        end
      end

      context "when client configurations are provided" do

        context "when a default is provided" do

          before do
            described_class.load!(file, :test_with_max_staleness)
          end

          let(:default) do
            described_class.clients[:default]
          end

          it "sets the default hosts" do
            expect(default[:hosts]).to eq(SpecConfig.instance.addresses)
            # and make sure the value is not empty
            expect(default[:hosts].first).to include(':')
          end

          context "when the default has options" do

            let(:options) do
              default["options"]
            end

            it "sets the read option" do
              expect(options["read"]).to eq({ "mode" => :primary_preferred,
                                              "max_staleness" => 100 })
            end
          end
        end
      end
    end
  end

  describe "#options=" do

    context "when there are no options" do

      before do
        described_class.options = nil
      end

      it "does not try to assign options" do
        expect(described_class.preload_models).to be false
      end
    end

    context "when provided a non-existent option" do

      it "raises an error" do
        expect {
          described_class.options = { bad_option: true }
        }.to raise_error(Mongoid::Errors::InvalidConfigOption)
      end
    end
  end

  describe "#clients=" do

    context "when no clients configuration exists" do

      it "raises an error" do
        expect {
          described_class.send(:clients=, nil)
        }.to raise_error(Mongoid::Errors::NoClientsConfig)
      end
    end

    context "when no default client exists" do

      it "raises an error" do
        expect {
          described_class.send(:clients=, {})
        }.to raise_error(Mongoid::Errors::NoDefaultClient)
      end
    end

    context "when a default client exists" do

      context "when no hosts are provided" do

        let(:clients) do
          { "default" => { database: database_id }}
        end

        it "raises an error" do
          expect {
            described_class.send(:clients=, clients)
          }.to raise_error(Mongoid::Errors::NoClientHosts)
        end
      end

      context "when no database is provided" do

        let(:clients) do
          { "default" => { hosts: [ "127.0.0.1:27017" ] }}
        end

        it "raises an error" do
          expect {
            described_class.send(:clients=, clients)
          }.to raise_error(Mongoid::Errors::NoClientDatabase)
        end
      end

      context "when a uri and standard options are provided" do

        let(:clients) do
          { "default" =>
            { hosts: [ "127.0.0.1:27017" ], uri: "mongodb://127.0.0.1:27017" }
          }
        end

        it "raises an error" do
          expect {
            described_class.send(:clients=, clients)
          }.to raise_error(Mongoid::Errors::MixedClientConfiguration)
        end
      end
    end
  end

  describe '.log_level=' do
    around do |example|
      saved_log_level = Mongoid::Config.log_level
      begin
        example.run
      ensure
        Mongoid::Config.log_level = saved_log_level
      end
    end

    it 'accepts a string' do
      Mongoid::Config.log_level = 'info'
      expect(Mongoid::Config.log_level).to eq(1)

      # set twice to ensure value changes from default, whatever the default is
      Mongoid::Config.log_level = 'warn'
      expect(Mongoid::Config.log_level).to eq(2)
    end

    it 'accepts an integer' do
      Mongoid::Config.log_level = 1
      expect(Mongoid::Config.log_level).to eq(1)

      # set twice to ensure value changes from default, whatever the default is
      Mongoid::Config.log_level = 2
      expect(Mongoid::Config.log_level).to eq(2)
    end
  end
end
