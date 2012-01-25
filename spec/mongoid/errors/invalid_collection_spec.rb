require "spec_helper"

describe Mongoid::Errors::InvalidCollection do

  describe "#message" do

    context "default" do

      let(:klass) do
        Address
      end

      let(:error) do
        described_class.new(klass)
      end

      it "contains the problem in the message" do
        error.message.should include(
          "Access to the collection for Address is not allowed."
        )
      end

      it "contains the summary in the message" do
        error.message.should include(
          "Address.collection was called, and Address is an embedded document"
        )
      end

      it "contains the resolution in the message" do
        error.message.should include(
          "For access to the collection that the embedded document is in"
        )
      end
    end
  end
end
