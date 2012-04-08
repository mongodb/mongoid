require "spec_helper"

describe Mongoid::Errors::InvalidIndex do

  describe "#message" do

    let(:error) do
      described_class.new(Band, { name: 1, options: { invalid: true }})
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Invalid index specification on Band:"
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Indexes in Mongoid are defined as a hash of field name and direction"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Ensure that the index conforms to the correct syntax"
      )
    end
  end
end
