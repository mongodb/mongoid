require "spec_helper"

describe Mongoid::Errors::InvalidType do

  describe "#message" do

    let(:error) do
      described_class.new(Array, "Test")
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Field was defined as a(n) Array, but received a String with the value \"Test\"."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Some types in Mongoid prevent you from setting them"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Set the proper type, Array"
      )
    end
  end
end
