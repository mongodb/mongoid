require "spec_helper"

describe Mongoid::Errors::VersioningNotOnRoot do

  describe "#message" do

    let(:error) do
      described_class.new(Address)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Versioning not allowed on embedded document: Address."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Mongoid::Versioning behaviour is only allowed on documents"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Remove the versioning from the embedded Address"
      )
    end
  end
end
