require "spec_helper"

describe Mongoid::Errors::InvalidSubclassType do

  describe "#message" do

    let(:error) do
      described_class.new(Person, "Dog")
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Invalid subclass type 'Dog' for Person"
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Only the type of subclass of Person can be assigned to _type field."
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Verify if the value to be a subclass name of Person"
      )
    end
  end
end
