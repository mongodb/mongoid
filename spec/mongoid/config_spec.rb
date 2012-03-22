# encoding: utf-8
require "spec_helper"

describe Mongoid::Config do

  after(:all) do
    if defined?(RailsTemp)
      Rails = RailsTemp
    end
  end

  let(:standard_config) do
    File.join(File.dirname(__FILE__), "..", "config", "mongoid.yml")
  end

  let(:utc_config) do
    File.join(File.dirname(__FILE__), "..", "config", "mongoid_with_utc.yml")
  end

  let(:multi_config) do
    File.join(File.dirname(__FILE__), "..", "config", "mongoid_with_multiple_mongos.yml")
  end

  let(:replset_config) do
    File.join(File.dirname(__FILE__), "..", "config", "mongoid.replset.yml")
  end

  let(:mongohq_config) do
    File.join(File.dirname(__FILE__), "..", "config", "mongoid.mongohq.yml")
  end

  before(:all) do
    described_class.logger = nil
  end

  after do
    Mongoid.configure do |config|
      config.master = Mongo::Connection.new(HOST, PORT).db(database_id)
      config.logger = nil
    end
  end

  describe ".destructive_fields" do

    it "returns a list of method names" do
      described_class.destructive_fields.should include(:process_attributes)
    end
  end

  describe ".from_hash" do

    before do
      described_class.from_hash(settings["test"])
    end

    after do
      described_class.reset
    end

    context "when using a standard configuration" do

      let(:settings) do
        YAML.load(ERB.new(File.new(standard_config).read).result)
      end

      it "sets the master db" do
        described_class.master.name.should eq("mongoid_config_test")
      end

      it "sets allow_dynamic_fields" do
        described_class.allow_dynamic_fields.should be_false
      end

      it "sets include_root_in_json" do
        described_class.include_root_in_json.should be_true
      end

      it "sets scope_overwrite_exception" do
        described_class.scope_overwrite_exception.should be_false
      end

      it "sets persist_in_safe_mode" do
        described_class.persist_in_safe_mode.should be_false
      end

      it "sets raise_not_found_error" do
        described_class.raise_not_found_error.should be_false
      end

      it "returns nil, which is interpreted as the local time_zone" do
        described_class.use_utc.should be_false
      end

      it "sets the logger to nil" do
        described_class.logger.should be_nil
      end
    end

    context "when configuring with utc time" do

      let(:settings) do
        YAML.load(ERB.new(File.new(utc_config).read).result)
      end

      it "sets the utc flag" do
        described_class.use_utc.should be_true
      end
    end

    context "when configuring with multiple databases" do

      let(:settings) do
        YAML.load(ERB.new(File.new(multi_config).read).result)
      end

      let(:databases) do
        described_class.databases["secondary"]
      end

      let(:slaves) do
        described_class.databases["secondary_slaves"]
      end

      it "sets the secondary master database" do
        databases.name.should eq("secondary_config_test")
      end

      it "sets the secondary slaves" do
        slaves.each do |slave|
          slave.name.should eq("secondary_config_test")
        end
      end
    end

    context "when configuring with mongohq", config: :mongohq do

      let(:settings) do
        YAML.load(ERB.new(File.new(mongohq_config).read).result)
      end

      it "sets the master db" do
        described_class.master.name.should eq("mongoid")
      end
    end
  end

  describe ".load!" do

    before(:all) do
      if defined?(Rails)
        RailsTemp = Rails
        Object.send(:remove_const, :Rails)
      end
    end

    context "when the rack environment is set" do

      before do
        ENV["RACK_ENV"] = "test"
        described_class.load!(standard_config)
      end

      after do
        ENV["RACK_ENV"] = nil
        described_class.reset
      end

      it "sets the master db" do
        described_class.master.name.should eq("mongoid_config_test")
      end

      it "sets allow_dynamic_fields" do
        described_class.allow_dynamic_fields.should be_false
      end

      it "sets include_root_in_json" do
        described_class.include_root_in_json.should be_true
      end

      it "sets scope_overwrite_exception" do
        described_class.scope_overwrite_exception.should be_false
      end

      it "sets persist_in_safe_mode" do
        described_class.persist_in_safe_mode.should be_false
      end

      it "sets raise_not_found_error" do
        described_class.raise_not_found_error.should be_false
      end

      it "returns nil, which is interpreted as the local time_zone" do
        described_class.use_utc.should be_false
      end
    end

    context "when provided an environment" do

      before do
        described_class.load!(standard_config, :test)
      end

      after do
        described_class.reset
      end

      it "sets the master db" do
        described_class.master.name.should eq("mongoid_config_test")
      end

      it "sets allow_dynamic_fields" do
        described_class.allow_dynamic_fields.should be_false
      end

      it "sets include_root_in_json" do
        described_class.include_root_in_json.should be_true
      end

      it "sets scope_overwrite_exception" do
        described_class.scope_overwrite_exception.should be_false
      end

      it "sets persist_in_safe_mode" do
        described_class.persist_in_safe_mode.should be_false
      end

      it "sets raise_not_found_error" do
        described_class.raise_not_found_error.should be_false
      end

      it "returns nil, which is interpreted as the local time_zone" do
        described_class.use_utc.should be_false
      end
    end
  end

  describe ".default_logger" do

    it "returns a Logger instance by default" do
      described_class.default_logger.should be_a(Logger)
    end
  end

  describe "#load!" do

    context "when passed a bad filename" do

      it "raises an error" do
        expect { subject.load!("foo") }.should raise_error
      end
    end
  end

  describe ".logger" do

    it "returns the configured logger (NilClass)" do
      described_class.logger.should be_a(NilClass)
    end
  end

  describe "#logger=" do

    let(:config) do
      described_class
    end

    after do
      config.logger = nil
    end

    context "when provided false" do

      before do
        config.logger = false
      end

      it "does not set the logger" do
        config.logger.should be_nil
      end
    end

    context "when provided true" do

      before do
        config.logger = true
      end

      it "sets the default logger" do
        config.logger.should be_a(::Logger)
      end
    end

    context "when provided nil" do

      before do
        config.logger = nil
      end

      it "does not set the logger" do
        config.logger.should be_nil
      end
    end

    context "when provided a logger" do

      let(:logger) do
        ::Logger.new($stdout)
      end

      before do
        config.logger = logger
      end

      it "sets the logger" do
        config.logger.should eq(logger)
      end
    end

    context "when provided an object that quacks like a logger" do

      let(:logger) do
        stub.quacks_like(::Logger.allocate)
      end

      before do
        config.logger = logger
      end

      it "sets the logger" do
        config.logger.should eq(logger)
      end
    end

    context "when provided an object that does not quack like a logger" do

      let(:logger) do
        stub
      end

      before do
        logger.expects(:respond_to?).with(:info).returns(false)
        config.logger = logger
      end

      it "does not the logger" do
        config.logger.should be_nil
      end
    end
  end

  describe ".master" do

    context "when a database was set" do

      it "returns the database" do
        described_class.master.name.should eq(database_id)
      end
    end
  end

  describe ".master=" do

    context "when provided a mongo database" do

      before do
        described_class.master = Mongo::Connection.new(HOST, PORT).db("mongoid_test")
      end

      it "sets the master" do
        described_class.master.name.should eq("mongoid_test")
      end
    end

    context "when not provided a mongo database" do

      it "raises an error" do
        expect {
          described_class.master = :testing
        }.to raise_error(Mongoid::Errors::InvalidDatabase)
      end
    end
  end

  describe ".option" do

    before(:all) do
      Mongoid::Config.option(:test_setting, default: true)
    end

    it "creates a getter for the option" do
      Mongoid::Config.should respond_to(:test_setting)
    end

    it "creates a setter for the option" do
      Mongoid::Config.should respond_to(:test_setting=)
    end

    it "creates a conditional for the option" do
      Mongoid::Config.should respond_to(:test_setting?)
    end

    it "allows the setting of a default value" do
      Mongoid::Config.test_setting.should be_true
    end
  end

  describe ".purge!" do

    before do
      Post.create(title: "testing")
    end

    context "when no collection name is provided" do

      before do
        Mongoid.purge!
      end

      it "purges the post collection" do
        Mongoid.master.collection("posts").count.should eq(0)
      end
    end
  end

  context "when defining options" do

    before do
      described_class.reset
    end

    describe ".allow_dynamic_fields" do

      it "defaults to true" do
        described_class.allow_dynamic_fields.should be_true
      end
    end

    describe ".identity_map_enabled" do

      it "defaults to false" do
        described_class.identity_map_enabled.should be_false
      end
    end

    describe ".include_root_in_json" do

      it "defaults to false" do
        described_class.include_root_in_json.should be_false
      end
    end

    describe ".scope_overwrite_exception" do

      it "defaults to false" do
        described_class.scope_overwrite_exception.should be_false
      end
    end

    describe ".persist_in_safe_mode" do

      it "defaults to false" do
        described_class.persist_in_safe_mode.should be_false
      end
    end

    describe ".preload_models" do

      it "defaults to false" do
        described_class.preload_models.should be_false
      end
    end

    describe ".raise_not_found_error" do

      it "defaults to true" do
        described_class.raise_not_found_error.should be_true
      end
    end

    describe ".autocreate_indexes" do

      it "defaults to false" do
        described_class.autocreate_indexes.should be_false
      end
    end

    describe ".skip_version_check" do

      it "defaults to false" do
        described_class.skip_version_check.should be_false
      end
    end

    describe ".time_zone" do

      it "defaults to nil" do
        described_class.time_zone.should be_nil
      end
    end

    describe "#use_activesupport_time_zone" do

      it "defaults to true" do
        described_class.use_activesupport_time_zone.should be_true
      end
    end
  end

  describe ".reset" do

    it "reverts to the defaults" do
      described_class.reset.should eq(described_class.defaults)
    end
  end
end
