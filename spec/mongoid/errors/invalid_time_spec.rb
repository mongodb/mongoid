# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidTime do

  describe "#message" do

    let(:error) do
      described_class.new("this is not a date")
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "'this is not a date' is not a valid Time."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Mongoid tries to serialize the values for Date, DateTime, and Time"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Make sure to pass parsable values to the field setter for Date"
      )
    end
  end
end
