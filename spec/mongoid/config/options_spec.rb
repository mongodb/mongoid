require "spec_helper"

describe Mongoid::Config::Options do

  let(:config) do
    Mongoid::Config
  end

  describe "#defaults" do

    it "returns the default options" do
      expect(config.defaults).to_not be_empty
    end
  end

  describe "#option" do

    context "when a default is provided" do

      after do
        config.preload_models = false
      end

      it "defines a getter" do
        expect(config.preload_models).to be false
      end

      it "defines a setter" do
        (config.preload_models = expect(true)).to be true
      end

      it "defines a presence check" do
        expect(config).to_not be_preload_models
      end
    end
  end

  describe "#reset" do

    before do
      config.preload_models = true
      config.reset
    end

    it "resets the settings to the defaults" do
      expect(config.preload_models).to be false
    end
  end

  describe "#settings" do

    it "returns the settings" do
      expect(config.settings).to_not be_empty
    end
  end
end
