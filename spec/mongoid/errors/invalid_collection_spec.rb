# frozen_string_literal: true

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
        expect(error.message).to include(
          "Access to the collection for Address is not allowed."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "Address.collection was called, and Address is an embedded document"
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          "For access to the collection that the embedded document is in"
        )
      end
    end
  end
end
