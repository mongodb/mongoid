require "spec_helper"

describe Mongoid::Errors::ScopeOverwrite do

  describe "#message" do

    let(:error) do
      described_class.new("Person", "scope")
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Cannot create scope :scope, because of existing method Person.scope."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "When defining a scope that conflicts with a method that already exists"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Change the name of the scope so it does not conflict with the already"
      )
    end
  end
end
