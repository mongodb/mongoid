# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::NoEnvironment do

  describe "#message" do

    let(:error) do
      described_class.new
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Could not load the configuration since no environment was defined."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Mongoid could not find an environment setting in any of the following"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Please ensure an environment is set in one of the mentioned locations"
      )
    end
  end
end
