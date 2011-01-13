require "spec_helper"

describe Mongoid::Config::ReplsetDatabase do

  let(:replset_config) do
    File.join(File.dirname(__FILE__), "..", "..", "..", "config", "mongoid.replset.yml")
  end

  describe "#configure" do

    it "should create a valid Mongo::ReplSetConnection" do
      options = YAML.load(ERB.new(File.new(replset_config).read).result)
      res = described_class.new(options['test']).configure
      res[0].connection.should be_a(Mongo::ReplSetConnection)
      res[0].connection.slave_ok?.should be_true
      res[1].should be_nil
    end

  end

end
