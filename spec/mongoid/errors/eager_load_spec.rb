require "spec_helper"

describe Mongoid::Errors::EagerLoad do

  describe "#message" do

    let(:error) do
      described_class.new(:preferences)
    end

    it "returns the warning of eager loading many to manies" do
      error.message.should include(
        "Eager loading :preferences is not supported"
      )
    end
  end
end
