require "spec_helper"

describe Mongoid::Errors::EagerLoad do

  describe "#message" do

    let(:error) do
      described_class.new(:ratable)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Eager loading :ratable is not supported since it is a polymorphic"
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Mongoid cannot currently determine the classes it needs to eager"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Don't attempt to perform this action and have patience"
      )
    end
  end
end
