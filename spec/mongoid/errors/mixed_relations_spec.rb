require "spec_helper"

describe Mongoid::Errors::MixedRelations do

  describe "#message" do

    let(:error) do
      described_class.new(Post, Address)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Referencing a(n) Address document from the Post document"
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "In order to properly access a(n) Address from Post the reference"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Consider not embedding Address, or do the key storage"
      )
    end
  end
end
