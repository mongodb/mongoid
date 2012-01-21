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

      it "contains class is not allowed" do
        error.message.should include("Address is not allowed")
      end
    end
  end
end
