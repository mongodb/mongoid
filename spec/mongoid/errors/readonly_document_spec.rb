# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::ReadonlyDocument do

  describe "#message" do

    let(:error) do
      described_class.new(Band)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Attempted to persist a readonly document of class 'Band'."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Documents that are marked readonly cannot be persisted"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Don't attempt to persist documents that are flagged as readonly."
      )
    end
  end
end
