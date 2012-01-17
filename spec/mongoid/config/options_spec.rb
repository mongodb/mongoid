require "spec_helper"

describe Mongoid::Config::Options do

  let(:config) do
    Mongoid::Config
  end

  describe "#defaults" do

    it "returns the default options" do
      config.defaults.should_not be_empty
    end
  end

  describe "#option" do

    context "when no default is provided" do

      after do
        config.time_zone = nil
      end

      it "defines a getter" do
        config.time_zone.should be_nil
      end

      it "defines a setter" do
        (config.time_zone = "Berlin").should eq("Berlin")
      end

      it "defines a presence check" do
        config.should_not be_time_zone
      end
    end

    context "when a default is provided" do

      after do
        config.persist_in_safe_mode = false
      end

      it "defines a getter" do
        config.persist_in_safe_mode.should be_false
      end

      it "defines a setter" do
        (config.persist_in_safe_mode = true).should be_true
      end

      it "defines a presence check" do
        config.should_not be_persist_in_safe_mode
      end
    end
  end

  describe "#reset" do

    before do
      config.persist_in_safe_mode = true
      config.reset
    end

    it "resets the settings to the defaults" do
      config.persist_in_safe_mode.should be_false
    end
  end

  describe "#settings" do

    it "returns the settings" do
      config.settings.should_not be_empty
    end
  end
end
