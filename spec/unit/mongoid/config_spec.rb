require "spec_helper"

describe Mongoid::Config do

  after :all do
    config.raise_not_found_error = true
  end

  let(:config) { Mongoid::Config.instance }

  describe "#database=" do

    context "when object provided is not a Mongo::DB" do

      it "raises an error" do
        lambda { config.database = "Test" }.should
          raise_error(Mongoid::Errors::InvalidDatabase)
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

  describe "#persist_types" do

    it "defaults to true" do
      config.persist_types.should == true
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

  describe "#use_object_ids" do

    it "defaults to false" do
      config.use_object_ids.should == false
    end
  end

end
