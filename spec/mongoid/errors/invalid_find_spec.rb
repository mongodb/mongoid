# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidFind do

  describe "#message" do

    let(:error) do
      described_class.new
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Calling Document.find with nil is invalid"
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Document.find expects the parameters to be 1 or more ids"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Most likely this is caused by passing parameters directly"
      )
    end
  end
end
