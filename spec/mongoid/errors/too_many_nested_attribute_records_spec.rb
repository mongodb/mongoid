# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::TooManyNestedAttributeRecords do

  describe "#message" do

    let(:error) do
      described_class.new("favorites", 5)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Accepting nested attributes for favorites is limited to 5 documents."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "More documents were sent to be processed than the allowed limit."
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "The limit is set as an option to the macro, for example:"
      )
    end
  end
end
