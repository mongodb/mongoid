# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidOptions do

  describe "#message" do

    let(:error) do
      described_class.new(:name, :invalid, [ :valid ])
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Invalid option :invalid provided to association :name."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Mongoid checks the options that are passed to the association macros"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Valid options are: valid, make sure these are the ones you are using."
      )
    end
  end
end
