require "spec_helper"

describe Mongoid::Errors::InvalidField do

  describe "#message" do

    let(:error) do
      described_class.new("collection")
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Defining a field named collection is not allowed."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Defining fields that conflict with Mongoid internal attributes"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Use Mongoid.destructive_fields to see what names are not allowed"
      )
    end
  end
end
