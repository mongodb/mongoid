# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidScope do

  describe "#message" do

    let(:error) do
      described_class.new(Band, {})
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Defining a scope of value {} on Band is not allowed."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Scopes in Mongoid must be procs that wrap"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Change the scope to be a proc wrapped criteria."
      )
    end
  end
end
