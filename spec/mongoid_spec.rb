require "spec_helper"

describe Mongoid do

  describe ".configure" do

    context "when no block supplied" do

      it "returns the config singleton" do
        expect(Mongoid.configure).to eq(Mongoid::Config)
      end
    end

    context "when a block is supplied" do

      before do
        Mongoid.configure do |config|
          config.preload_models = true
        end
      end

      after do
        Mongoid.configure do |config|
          config.preload_models = false
        end
      end

      it "sets the values on the config instance" do
        expect(Mongoid.preload_models).to be true
      end
    end
  end

  describe ".default_session" do

    it "returns the default session" do
      expect(Mongoid.default_session).to eq(Mongoid::Sessions.default)
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
          expect(node.send(:connected?)).to be false
        end
      end
    end
  end

  describe ".session" do

    it "returns the named session" do
      expect(Mongoid.session(:default)).to eq(Mongoid::Sessions.default)
    end
  end

  describe ".models" do

    it "returns the list of known models" do
      expect(Mongoid.models).to include(Band)
    end
  end
end
