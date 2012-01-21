require "spec_helper"

describe Mongoid::Errors::InvalidDatabase do

  describe "#message" do

    let(:error) do
      described_class.new("Test")
    end

    it "returns a message with the bad db object class" do
      error.message.should include("String")
    end
  end
end
