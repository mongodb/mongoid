require 'spec_helper'

describe Mongoid::Errors::AmbiguousRelationship do

  describe "#message" do

    let(:error) do
      described_class.new(Person, Drug)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "There are multiple relations on Person which fit to Drug."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        ""
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        ""
      )
    end
  end
end
