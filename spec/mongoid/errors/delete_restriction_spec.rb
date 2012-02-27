require "spec_helper"

describe Mongoid::Errors::DeleteRestriction do

  describe "#message" do

    let(:error) do
      described_class.new(Person.new, :drugs)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Cannot delete Person because of dependent drugs."
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
