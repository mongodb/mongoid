require "spec_helper"

describe Mongoid::Errors::NoClientConfig do

  describe "#message" do

    let(:error) do
      described_class.new(:secondary)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "No configuration could be found for a client named 'secondary'."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "When attempting to create the new client, Mongoid could not find a client"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Double check your mongoid.yml to make sure under the clients"
      )
    end
  end
end
