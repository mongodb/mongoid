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
  end
end
