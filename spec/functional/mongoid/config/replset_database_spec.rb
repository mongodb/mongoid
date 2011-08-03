require "spec_helper"

describe Mongoid::Config::ReplsetDatabase do

  let(:replset_config) do
    File.join(File.dirname(__FILE__), "..", "..", "..", "config", "mongoid.replset.yml")
  end

  describe "#configure" do

    let(:options) do
      YAML.load(ERB.new(File.new(replset_config).read).result)
    end

    let(:replica_set) do
      described_class.new(options['test']).configure
    end

    it "returns a replica set connection" do
      replica_set[0].connection.should be_a(Mongo::ReplSetConnection)
    end

    it "sets slave ok to true" do
      replica_set[0].connection.slave_ok?.should be_true
    end

    it "does not configure specific slaves" do
      replica_set[1].should be_nil
    end

    context "without authentication details" do

      let(:replica_set) do
        described_class.new(options['test'])
      end

      let(:repl_set_connection) do
        stub.quacks_like(Mongo::ReplSetConnection.allocate)
      end

      before do
        Mongo::ReplSetConnection.stubs(:new).returns(repl_set_connection)
        repl_set_connection.expects(:db)
        repl_set_connection.expects(:add_auth).never
        repl_set_connection.expects(:apply_saved_authentication).never
        replica_set.configure
      end

      it "sets up the default mongoid logger" do
        replica_set.logger.should eq(Mongoid::Config.logger)
      end
    end

    context "with authentication details" do

      let(:replica_set) do
        described_class.new(options['authenticated']).configure
      end

      let(:repl_set_connection) do
        stub.quacks_like(Mongo::ReplSetConnection.allocate)
      end

      before do
        Mongo::ReplSetConnection.stubs(:new).returns(repl_set_connection)
      end

      it "should add authentication and apply" do
        repl_set_connection.expects(:db)
        repl_set_connection.expects(:add_auth).with(options['authenticated']['database'], options['authenticated']['username'], options['authenticated']['password'])
        repl_set_connection.expects(:apply_saved_authentication)
        replica_set
      end
    end
  end
end
