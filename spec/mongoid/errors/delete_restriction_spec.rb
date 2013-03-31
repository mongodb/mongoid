require "spec_helper"

describe Mongoid::Errors::DeleteRestriction do

  describe "#message" do

    let(:error) do
      described_class.new(Person.new, :drugs)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Cannot delete Person because of dependent 'drugs'."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "When defining 'drugs' with a :dependent => :restrict,"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Don't attempt to delete the parent Person when it has children"
      )
    end
  end
end
