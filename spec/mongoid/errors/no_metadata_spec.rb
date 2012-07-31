require 'spec_helper'

describe Mongoid::Errors::NoMetadata do

  describe "#message" do

    let(:error) do
      described_class.new(Address)
    end

    it "contains the problem in the message" do
      error.message.should include("Metadata not found for document of type Address.")
    end

    it "contains the summary in the message" do
      error.message.should include("Mongoid sets the metadata of a relation on the")
    end

    it "contains the resolution in the message" do
      error.message.should include("Ensure that your relations on the Address model")
    end
  end
end
