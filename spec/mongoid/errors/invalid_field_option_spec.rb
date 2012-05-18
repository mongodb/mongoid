require "spec_helper"

describe Mongoid::Errors::InvalidFieldOption do

  describe "#message" do

    let(:error) do
      described_class.new(Person, :testing, :localized, [ :localize ])
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Invalid option :localized provided for field :testing."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Mongoid requires that you only provide valid options"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "When defining the field :testing on 'Person', please"
      )
    end
  end
end
