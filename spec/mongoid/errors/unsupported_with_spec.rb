# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::UnsupportedWith do

  describe "#message" do

    let(:error) do
      described_class.new
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Calling #with on a document instance is not supported"
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Mongoid does not support calling #with on instances of a"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Please use the #with! method instead. Note that #with!"
      )
    end
  end
end
