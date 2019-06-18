# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Errors::InvalidStorageOptions do

  describe "#message" do

    let(:error) do
      described_class.new(Band, :bad_option)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Invalid options passed to Band.store_in: bad_option."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "The :store_in macro takes only a hash of parameters with the"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Change the options passed to store_in to match the documented API"
      )
    end
  end
end
