require "spec_helper"

describe Mongoid::Errors::UnsupportedVersion do

  describe "#message" do

    let(:version) do
      "1.2.4"
    end

    let(:error) do
      described_class.new(version)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "MongoDB 1.2.4 not supported, please upgrade to"
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Mongoid is relying on features that were introduced"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Upgrade your MongoDB instances or keep Mongoid"
      )
    end
  end
end
