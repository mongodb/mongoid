require "spec_helper"

describe Mongoid::Errors::ScopeOverwrite do

  describe "#message" do

    let(:error) do
      described_class.new("Person", "scope")
    end

    it "returns the scope overwrite message" do
      error.message.should eq(
        "Cannot create scope :scope, because of existing method Person.scope."
      )
    end
  end
end
