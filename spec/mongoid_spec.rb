require "spec_helper"

describe Mongoid do

  describe ".configure" do

    context "when no block supplied" do

      it "returns the config singleton" do
        Mongoid.configure.should eq(Mongoid::Config)
      end
    end

    context "when a block is supplied" do

      before do
        Mongoid.configure do |config|
          config.allow_dynamic_fields = false
        end
      end

      after do
        Mongoid.configure do |config|
          config.allow_dynamic_fields = true
        end
      end

      it "sets the values on the config instance" do
        Mongoid.allow_dynamic_fields.should be_false
      end
    end
  end

  describe ".default_session" do

    it "returns the default session" do
      Mongoid.default_session.should eq(Mongoid::Sessions.default)
    end
  end

  describe ".disconnect_sessions" do

    let(:sessions) do
      Mongoid::Threaded.sessions.values
    end

    before do
      Band.all.entries
      Mongoid.disconnect_sessions
    end

    it "disconnects from all active sessions" do
      sessions.each do |session|
        session.cluster.nodes.each do |node|
          node.send(:connected?).should be_false
        end
      end
    end
  end

  describe ".session" do

    it "returns the named session" do
      Mongoid.session(:default).should eq(Mongoid::Sessions.default)
    end
  end

  describe ".models" do

    it "returns the list of known models" do
      Mongoid.models.should include(Band)
    end
  end
end
