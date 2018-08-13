# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::UnsupportedJavascript do

  describe "#message" do

    let(:error) do
      described_class.new(Address, "this.street == null")
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Executing Javascript $where selector on an embedded criteria is not supported"
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Mongoid only supports providing a hash of arguments to #where"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Please provide a standard hash to #where when the criteria"
      )
    end
  end
end
