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

    context "when a default session config exists" do

      context "when a default database is configured" do

        let(:config) do
          {
            default: {
              database: database_id,
              hosts: [ "localhost:27017" ]
            }
          }
        end

        before do
          described_class.sessions = config
        end

        it "returns true" do
          expect(described_class).to be_configured
        end
      end
    end

    context "when no default session config exists" do

      before do
        described_class.sessions.clear
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

    context "when existing sessions exist in the configuration" do

      let(:session) do
        Moped::Session.new([ "127.0.0.1:27017" ])
      end

      before do
        Mongoid::Threaded.sessions[:test] = session
        described_class.load!(file, :test)
      end

      it "clears the previous sessions" do
        expect(Mongoid::Threaded.sessions[:test]).to be_nil
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

      context "when session configurations are provided" do

        context "when a default is provided" do

          before do
            described_class.load!(file)
          end

          let(:default) do
            described_class.sessions[:default]
          end

          it "sets the default hosts" do
            expect(default[:hosts]).to eq(["#{HOST}:#{PORT}"])
          end

          context "when the default has options" do

            let(:options) do
              default["options"]
            end

            it "sets the read option" do
              expect(options["read"]).to eq("primary")
            end
          end
        end

        context "when a secondary is provided", config: :mongohq do

          before do
            described_class.load!(file)
          end

          let(:secondary) do
            described_class.sessions[:mongohq_single]
          end

          it "sets the secondary host" do
            expect(secondary["hosts"]).to eq([ ENV["MONGOHQ_SINGLE_URL"] ])
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

    context "when provided a non-existant option" do

      it "raises an error" do
        expect {
          described_class.options = { bad_option: true }
        }.to raise_error(Mongoid::Errors::InvalidConfigOption)
      end
    end
  end

  describe "#sessions=" do

    context "when no sessions configuration exists" do

      it "raises an error" do
        expect {
          described_class.sessions = nil
        }.to raise_error(Mongoid::Errors::NoSessionsConfig)
      end
    end

    context "when no default session exists" do

      it "raises an error" do
        expect {
          described_class.sessions = {}
        }.to raise_error(Mongoid::Errors::NoDefaultSession)
      end
    end

    context "when a default session exists" do

      context "when no hosts are provided" do

        let(:sessions) do
          { "default" => { database: database_id }}
        end

        it "raises an error" do
          expect {
            described_class.sessions = sessions
          }.to raise_error(Mongoid::Errors::NoSessionHosts)
        end
      end

      context "when no database is provided" do

        let(:sessions) do
          { "default" => { hosts: [ "localhost:27017" ] }}
        end

        it "raises an error" do
          expect {
            described_class.sessions = sessions
          }.to raise_error(Mongoid::Errors::NoSessionDatabase)
        end
      end

      context "when a uri and standard options are provided" do

        let(:sessions) do
          { "default" =>
            { hosts: [ "localhost:27017" ], uri: "mongodb://localhost:27017" }
          }
        end

        it "raises an error" do
          expect {
            described_class.sessions = sessions
          }.to raise_error(Mongoid::Errors::MixedSessionConfiguration)
        end
      end
    end
  end
end
