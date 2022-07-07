# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::NoEnvironment do

  describe "#message" do

    let(:error) do
      described_class.new
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Mongoid could not determine the environment"
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "it was not specified in any of the following locations"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Please ensure an environment is set"
      )
    end
  end
end
