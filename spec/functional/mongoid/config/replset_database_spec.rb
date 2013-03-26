require "spec_helper"

describe Mongoid::Config::ReplsetDatabase do

  let(:replset_config) do
    File.join(File.dirname(__FILE__), "..", "..", "..", "config", "mongoid.replset.yml")
  end

  describe "#configure" do

    let(:options) do
      YAML.load(ERB.new(File.new(replset_config).read).result)
    end

    context "without authentication details" do

      let(:replica_set) do
        described_class.new(options['test'])
      end

      before do
        Mongo::ReplSetConnection.any_instance.stubs(:connect).returns(true)
      end

      it "is configurable" do
        replica_set.configure.should be
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
