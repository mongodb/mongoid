# frozen_string_literal: true

require "spec_helper"

describe Mongoid do

  describe ".configure" do

    context "when no block supplied" do

      it "returns the config singleton" do
        expect(Mongoid.configure).to eq(Mongoid::Config)
      end
    end

    context "when a block is given" do
      config_override :preload_models, false

      context "with arity 0" do

        before do
          Mongoid.configure do
            config.preload_models = true
          end
        end

        it "sets the values on the config instance" do
          expect(Mongoid.preload_models).to be true
        end
      end

      context "with arity 1" do

        before do
          Mongoid.configure do |config|
            config.preload_models = true
          end
        end

        it "sets the values on the config instance" do
          expect(Mongoid.preload_models).to be true
        end
      end

      context "with arity 2" do

        before do
          Mongoid.configure do |config, _other|
            config.preload_models = true
          end
        end

        it "sets the values on the config instance" do
          expect(Mongoid.preload_models).to be true
        end
      end
    end
  end

  describe ".default_client" do

    it "returns the default client" do
      expect(Mongoid.default_client).to eq(Mongoid::Clients.default)
    end
  end

  describe ".disconnect_clients" do

    let(:clients) do
      Mongoid::Clients.clients.values
    end

    before do
      Band.all.entries
    end

    it "disconnects from all active clients" do
      pending 'https://jira.mongodb.org/browse/MONGOID-5621'

      clients.each do |client|
        expect(client.cluster).to receive(:disconnect!).and_call_original
      end
      Mongoid.disconnect_clients
    end
  end

  describe ".client" do

    it "returns the named client" do
      expect(Mongoid.client(:default)).to eq(Mongoid::Clients.default)
    end
  end

  describe ".models" do

    it "returns the list of known models" do
      expect(Mongoid.models).to include(Band)
    end
  end
end
