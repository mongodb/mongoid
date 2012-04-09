# encoding: utf-8
require "spec_helper"

describe Mongoid::Config do

  after(:all) do
    if defined?(RailsTemp)
      Rails = RailsTemp
    end
  end

  describe "#destructive_fields" do

    Mongoid::Components.prohibited_methods.each do |method|

      it "contains #{method}" do
        described_class.destructive_fields.should include(method)
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

    context "when provided an environment" do

      before do
        described_class.load!(file, :test)
      end

      after do
        described_class.reset
      end

      it "sets the allow dynamic fields option" do
        described_class.allow_dynamic_fields.should be_true
      end

      it "sets the identity map option" do
        described_class.identity_map_enabled.should be_false
      end

      it "sets the include root in json option" do
        described_class.include_root_in_json.should be_false
      end

      it "sets the include type with serialization option" do
        described_class.include_type_for_serialization.should be_false
      end

      it "sets the scope overwrite option" do
        described_class.scope_overwrite_exception.should be_false
      end

      it "sets the preload models option" do
        described_class.preload_models.should be_false
      end

      it "sets the raise not found error option" do
        described_class.raise_not_found_error.should be_true
      end

      it "sets the skip version check option" do
        described_class.skip_version_check.should be_true
      end

      it "sets the use activesupport time zone option" do
        described_class.use_activesupport_time_zone.should be_true
      end

      it "sets the use utc option" do
        described_class.use_utc.should be_false
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

        it "sets the allow dynamic fields option" do
          described_class.allow_dynamic_fields.should be_true
        end

        it "sets the identity map option" do
          described_class.identity_map_enabled.should be_false
        end

        it "sets the include root in json option" do
          described_class.include_root_in_json.should be_false
        end

        it "sets the include type with serialization option" do
          described_class.include_type_for_serialization.should be_false
        end

        it "sets the scope overwrite option" do
          described_class.scope_overwrite_exception.should be_false
        end

        it "sets the preload models option" do
          described_class.preload_models.should be_false
        end

        it "sets the raise not found error option" do
          described_class.raise_not_found_error.should be_true
        end

        it "sets the skip version check option" do
          described_class.skip_version_check.should be_true
        end

        it "sets the use activesupport time zone option" do
          described_class.use_activesupport_time_zone.should be_true
        end

        it "sets the use utc option" do
          described_class.use_utc.should be_false
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
            default[:hosts].should eq(["#{HOST}:#{PORT}"])
          end

          context "when the default has options" do

            let(:options) do
              default["options"]
            end

            it "sets the consistency option" do
              options["consistency"].should eq(:strong)
            end
          end
        end

        context "when a secondary is provided" do

          before do
            described_class.load!(file)
          end

          let(:secondary) do
            described_class.sessions[:mongohq_single]
          end

          it "sets the secondary host" do
            secondary["hosts"].should eq([ ENV["MONGOHQ_SINGLE_URL"] ])
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
        described_class.allow_dynamic_fields.should be_true
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
    end
  end
end
