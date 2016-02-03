# encoding: utf-8
require "spec_helper"

describe Mongoid::Config do

  after(:all) do
    if defined?(RailsTemp)
      Rails = RailsTemp
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
        RailsTemp = Rails
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

      it "clears the previous clients" do
        expect(Mongoid::Clients.clients[:test]).to be_nil
      end
    end

    context "when the log level is set in the configuration" do

      before do
        described_class.load!(file, :test)
      end

      after do
        Mongoid.configure do |config|
          config.load_configuration(CONFIG)
        end
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
            RailsTemp = Rails
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
      end

      context "when client configurations are provided" do

        context "when a default is provided" do

          before do
            described_class.load!(file)
          end

          let(:default) do
            described_class.clients[:default]
          end

          it "sets the default hosts" do
            expect(default[:hosts]).to eq(["#{HOST}:#{PORT}"])
          end

          context "when the default has options" do

            let(:options) do
              default["options"]
            end

            it "sets the read option" do
              expect(options["read"]).to eq({ "mode" => :primary_preferred,
                                              "tag_sets" => [{ "use" => "web" }]})
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
end
