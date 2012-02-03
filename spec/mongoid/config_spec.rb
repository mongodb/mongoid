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
        described_class.allow_dynamic_fields.should be_false
      end

      it "sets the autocreate indexes option" do
        described_class.autocreate_indexes.should be_true
      end

      it "sets the identity map option" do
        described_class.identity_map_enabled.should be_true
      end

      it "sets the include root in json option" do
        described_class.include_root_in_json.should be_true
      end

      it "sets the include type with serialization option" do
        described_class.include_type_for_serialization.should be_true
      end

      it "sets the scope overwrite option" do
        described_class.scope_overwrite_exception.should be_true
      end

      it "sets the preload models option" do
        described_class.preload_models.should be_true
      end

      it "sets the raise not found error option" do
        described_class.raise_not_found_error.should be_false
      end

      it "sets the skip version check option" do
        described_class.skip_version_check.should be_false
      end

      it "sets the use activesupport time zone option" do
        described_class.use_activesupport_time_zone.should be_false
      end

      it "sets the use utc option" do
        described_class.use_utc.should be_true
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
          described_class.allow_dynamic_fields.should be_false
        end

        it "sets the autocreate indexes option" do
          described_class.autocreate_indexes.should be_true
        end

        it "sets the identity map option" do
          described_class.identity_map_enabled.should be_true
        end

        it "sets the include root in json option" do
          described_class.include_root_in_json.should be_true
        end

        it "sets the include type with serialization option" do
          described_class.include_type_for_serialization.should be_true
        end

        it "sets the scope overwrite option" do
          described_class.scope_overwrite_exception.should be_true
        end

        it "sets the preload models option" do
          described_class.preload_models.should be_true
        end

        it "sets the raise not found error option" do
          described_class.raise_not_found_error.should be_false
        end

        it "sets the skip version check option" do
          described_class.skip_version_check.should be_false
        end

        it "sets the use activesupport time zone option" do
          described_class.use_activesupport_time_zone.should be_false
        end

        it "sets the use utc option" do
          described_class.use_utc.should be_true
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

            it "sets the default connect timeout" do
              options["connect_timeout"].should eq(10)
            end

            it "sets the default op timeout" do
              options["op_timeout"].should eq(30)
            end

            it "sets the default pool size" do
              options["pool_size"].should eq(1)
            end

            it "sets the default pool timeout" do
              options["pool_timeout"].should eq(5.0)
            end

            it "sets the default safe mode" do
              options["safe"].should be_false
            end

            it "sets the default slave ok option" do
              options["slave_ok"].should be_true
            end

            it "sets the default ssl option" do
              options["ssl"].should be_false
            end
          end
        end

        context "when a secondary is provided" do

          before do
            described_class.load!(file)
          end

          let(:secondary) do
            described_class.sessions["secondary"]
          end

          it "sets the secondary host" do
            secondary["hosts"].should eq(["localhost:27018","localhost:27019"])
          end

          context "when the secondary has options" do

            let(:options) do
              secondary["options"]
            end

            it "sets the secondary logger" do
              options["logger"].should be_true
            end

            it "sets the secondary read option" do
              options["read"].should eq(:secondary)
            end
          end
        end
      end

      context "when database configurations are provided" do

        before do
          described_class.load!(file)
        end

        context "when a default is provided" do

          let(:default) do
            described_class.databases[:default]
          end

          it "sets the default session" do
            default[:session].should eq("default")
          end

          it "sets the database name" do
            default[:name].should eq("mongoid_test")
          end
        end

        context "when a secondary is provided" do

          let(:secondary) do
            described_class.databases[:secondary]
          end

          it "sets the secondary session" do
            secondary[:session].should eq("secondary")
          end

          it "sets the database name" do
            secondary[:name].should eq("mongoid_replica_set")
          end

          context "when secondary options are provided" do

            let(:options) do
              secondary[:options]
            end

            it "sets the secondary safe option" do
              options[:safe].should be_true
            end
          end
        end

        context "when a tertiary is provided" do

          let(:tertiary) do
            described_class.databases[:tertiary]
          end

          it "sets the tertiary session" do
            tertiary[:session].should eq("default")
          end
        end
      end
    end
  end
end
