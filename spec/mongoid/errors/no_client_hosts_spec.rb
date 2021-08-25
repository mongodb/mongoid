# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::NoClientHosts do

  describe "#message" do

    let(:error) do
      described_class.new(:analytics, { database: "mongoid_test" })
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "No hosts provided for client configuration: :analytics."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Each client configuration must provide hosts so Mongoid"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "If configuring via a mongoid.yml, ensure that within your :analytics"
      )
    end
  end
end
