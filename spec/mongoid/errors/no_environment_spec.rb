require "spec_helper"

describe Mongoid::Errors::NoEnvironment do

  describe "#message" do

    let(:error) do
      described_class.new
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Could not load the configuration since no environment was defined."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Mongoid attempted to find the appropriate environment but no Rails.env"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Make sure some environment is set from the mentioned options"
      )
    end
  end
end
