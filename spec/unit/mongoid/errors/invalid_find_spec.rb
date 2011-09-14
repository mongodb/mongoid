require "spec_helper"

describe Mongoid::Errors::InvalidFind do

  describe "#message" do

    let(:error) do
      described_class.new
    end

    it "returns the warning find with nil" do
      error.message.should include(
        "Calling Document#find with nil is invalid"
      )
    end
  end
end
