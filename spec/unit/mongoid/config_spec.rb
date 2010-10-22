require "spec_helper"

describe Mongoid::Config do
  let(:config) { Class.new(Mongoid::Config).instance }

  before do
    config.reset
  end

  describe "#database=" do

    context "when object provided is not a Mongo::DB" do

      it "raises an error" do
        lambda { config.database = "Test" }.should
          raise_error(Mongoid::Errors::InvalidDatabase)
      end
    end
  end

  describe "#destructive_fields" do

    it "returns an array of bad field names" do
      config.destructive_fields.should include("collection")
    end
  end

  describe "#include_root_in_json" do

    it "defaults to false" do
      config.include_root_in_json.should be_false
    end
  end

  describe "#from_hash" do
    context "regular mongoid.yml" do
      before do
        file_name = File.join(File.dirname(__FILE__), "..", "..", "config", "mongoid.yml")
        @settings = YAML.load(ERB.new(File.new(file_name).read).result)
        config.from_hash(@settings["test"])
      end

      after { config.reset }

      it "sets the master db" do
        config.master.name.should == "mongoid_config_test"
      end

      it "sets allow_dynamic_fields" do
        config.allow_dynamic_fields.should == false
      end

      it "sets include_root_in_json" do
        config.include_root_in_json.should == true
      end

      it "sets reconnect_time" do
        config.reconnect_time.should == 5
      end

      it "sets parameterize keys" do
        config.parameterize_keys.should == false
      end

      it "sets persist_in_safe_mode" do
        config.persist_in_safe_mode.should == false
      end

      it "sets raise_not_found_error" do
        config.raise_not_found_error.should == false
      end

      it "returns nil, which is interpreted as the local time_zone" do
        config.use_utc.should be_false
      end
    end

    context "mongoid_with_utc.yml" do
      before do
        file_name = File.join(File.dirname(__FILE__), "..", "..", "config", "mongoid_with_utc.yml")
        file = File.new(file_name)
        @settings = YAML.load(file.read)["test"]
        config.from_hash(@settings)
      end

      after { config.reset }

      it "sets time_zone" do
        config.use_utc.should be_true
      end
    end

    context "mongoid_with_slaves.yml" do

      let(:connection) do
        stub(:server_version => version).quacks_like(Mongo::Connection.allocate)
      end

      let(:database) do
        stub(:kind_of? => true, :connection => connection).quacks_like(Mongo::DB.allocate)
      end

      let(:version) do
        Mongo::ServerVersion.new("2.0.0")
      end

      before do
        Mongo::Connection.stubs(:new => connection)
        connection.stubs(:db => database)
        database.stubs(:collections => []) #supress warning message from cleanup

        file_name = File.join(File.dirname(__FILE__), "..", "..", "config", "mongoid_with_slaves.yml")
        file = File.new(file_name)
        @settings = YAML.load(file.read)["test"]
        config.from_hash(@settings)
      end

      after { config.reset }

      it "sets slaves" do
        config.slaves.should_not be_empty
      end
    end

    context "with skip_version_check" do
      let(:settings) do
        {
          "host" => "localhost",
          "database" => "mongoid_config_test",
          "skip_version_check" => true,
        }
      end

      it "should set skip_version_check before it sets up the connection" do
        version_check_ordered = sequence('version_check_ordered')
        config.expects(:skip_version_check=).in_sequence(version_check_ordered)
        config.from_hash(settings)
      end
    end

    context "deferring connection" do
      let(:settings) do
        {
          "host" => "localhost",
          "database" => "mongoid_config_test",
        }
      end
      it "does not connect initially" do
        config.reset
        config.expects(:_master).never
        config.expects(:_slave).never
        config.from_hash(settings)
      end
      it "#master establishes deferred connection" do
        config.reset
        config.from_hash(settings)
        config.send(:instance_variable_get, :@master).should be_nil
        config.master.should_not be_nil
        config.send(:instance_variable_get, :@master).should_not be_nil
      end
    end
  end

  describe "#master=" do

    context "when object provided is not a Mongo::DB" do

      it "raises an error" do
        lambda { config.master = "Test" }.should
          raise_error(Mongoid::Errors::InvalidDatabase)
      end
    end

    context "when the database version is not supported" do

      let(:database) do
        stub.quacks_like(Mongo::DB.allocate)
      end

      let(:connection) do
        stub.quacks_like(Mongo::Connection.allocate)
      end

      let(:version) do
        Mongo::ServerVersion.new("1.3.0")
      end

      before do
        database.stubs(:kind_of?).returns(true)
        database.stubs(:connection).returns(connection)
        connection.stubs(:server_version).returns(version)
      end

      it "raises an error" do
        lambda { config.master = database }.should
          raise_error(Mongoid::Errors::UnsupportedVersion)
      end
    end
  end

  describe "#parameterize_keys" do

    it "defaults to true" do
      config.parameterize_keys.should == true
    end
  end

  describe "#persist_in_safe_mode=" do

    context "when setting to true" do

      before do
        config.persist_in_safe_mode = true
      end

      it "sets the value" do
        config.persist_in_safe_mode.should == true
      end

    end

    context "when setting to false" do

      before do
        config.persist_in_safe_mode = false
      end

      after do
        config.persist_in_safe_mode = true
      end

      it "sets the value" do
        config.persist_in_safe_mode.should == false
      end

    end

  end

  describe "#raise_not_found_error=" do

    context "when setting to true" do

      before do
        config.raise_not_found_error = true
      end

      it "sets the value" do
        config.raise_not_found_error.should == true
      end

    end

    context "when setting to false" do

      before do
        config.raise_not_found_error = false
      end

      it "sets the value" do
        config.raise_not_found_error.should == false
      end

    end

  end

  describe "#reconnect!" do

    context "with non-lazy reconnection option" do
      before do
        @connection = mock
        @master = mock
        config.expects(:master).returns(@master)
        @master.expects(:connection).returns(@connection)
      end

      context "default" do
        it "reconnects on the master connection" do
          @connection.expects(:connect).returns(true)
          config.reconnect!
        end
      end

      context "now=true" do
        it "reconnects on the master connection" do
          @connection.expects(:connect).returns(true)
          config.reconnect!(true)
        end
      end
    end

    context "with lazy reconnection option" do
      before do
        @master = mock
        config.stubs(:master).returns(@master)
      end

      it "sets a reconnection flag" do
        @master.expects(:connection).never
        config.reconnect!(false)
        config.instance_variable_get(:@reconnect).should be_true
      end
    end

  end

  describe "#master" do
    before do
      config.send(:instance_variable_set, :@master, master)
    end

    context "when the database has not been configured" do
      let(:master) { nil }
      it "should raise an error" do
        expect { config.master }.to raise_error(Mongoid::Errors::InvalidDatabase)
      end
    end

    context "when the database has been configured" do
      let(:connection) { mock }
      let(:master) { stub(:connection => connection) }

      it "returns the database" do
        config.master.should == master
      end

      context "when the reconnection flag is set" do
        before { config.reconnect!(false) }
        it "reconnects" do
          config.expects(:reconnect!)
          config.master
        end
      end
    end

  end

  describe "#reconnect_time" do

    it "defaults to 3" do
      config.reconnect_time.should == 3
    end

  end

  describe "#reconnect_time=" do

    after do
      config.reconnect_time = 3
    end

    it "sets the time" do
      config.reconnect_time = 5
      config.reconnect_time.should == 5
    end
  end

  describe "#slaves=" do

    context "when object provided is not a Mongo::DB" do

      it "raises an error" do
        lambda { config.slaves = ["Test"] }.should raise_error
      end
    end

    context "when the database version is not supported" do

      let(:database) do
        stub.quacks_like(Mongo::DB.allocate)
      end

      let(:connection) do
        stub.quacks_like(Mongo::Connection.allocate)
      end

      let(:version) do
        Mongo::ServerVersion.new("1.3.0")
      end

      before do
        database.stubs(:kind_of?).returns(true)
        database.stubs(:connection).returns(connection)
        connection.stubs(:server_version).returns(version)
      end

      it "raises an error" do
        lambda { config.slaves = [ database ] }.should
          raise_error(Mongoid::Errors::UnsupportedVersion)
      end
    end
  end

  describe "#allow_dynamic_fields=" do

    context "when setting to true" do

      before do
        config.allow_dynamic_fields = true
      end

      it "sets the value" do
        config.allow_dynamic_fields.should == true
      end
    end

    context "when setting to false" do

      before do
        config.allow_dynamic_fields = false
      end

      it "sets the value" do
        config.allow_dynamic_fields.should == false
      end
    end
  end
end
