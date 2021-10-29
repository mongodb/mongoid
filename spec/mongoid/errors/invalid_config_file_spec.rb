# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidConfigFile do

  describe "#message" do

    let(:error) do
      described_class.new('/my/path')
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Invalid configuration file: /my/path."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Your mongoid.yml configuration file does not contain the"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Ensure your configuration file contains the correct contents."
      )
    end
  end
end
