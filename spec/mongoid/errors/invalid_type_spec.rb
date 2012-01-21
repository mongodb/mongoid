require "spec_helper"

describe Mongoid::Errors::InvalidType do

  describe "#message" do

    let(:error) do
      described_class.new(Array, "Test")
    end

    it "returns a message with the bad type and supplied value" do
      error.message.should include("Array, but received a String")
    end
  end
end
