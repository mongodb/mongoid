require "spec_helper"

describe Mongoid::Errors::NoSessionHosts do

  describe "#message" do

    let(:error) do
      described_class.new(:secondary, { database: "mongoid_test" })
    end

    it "contains the problem in the message" do
      error.message.should include(
        "No hosts provided for session configuration: :secondary."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Each session configuration must provide hosts so Mongoid"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "If configuring via a mongoid.yml, ensure that within your :secondary"
      )
    end
  end
end
