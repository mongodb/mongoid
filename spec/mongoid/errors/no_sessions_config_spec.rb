require "spec_helper"

describe Mongoid::Errors::NoSessionsConfig do

  describe "#message" do

    let(:error) do
      described_class.new
    end

    it "contains the problem in the message" do
      error.message.should include(
        "No sessions configuration provided."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Mongoid's configuration requires that you provide details"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Double check your mongoid.yml to make sure that you have"
      )
    end
  end
end
