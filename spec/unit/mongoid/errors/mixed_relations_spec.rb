require "spec_helper"

describe Mongoid::Errors::MixedRelations do

  describe "#message" do

    let(:error) do
      described_class.new(Post, Address)
    end

    it "returns the warning of referencing embedded docs" do
      error.message.should include(
        "Referencing a(n) Address document from the Post document via a " +
        "relational association is not allowed since the Address is embedded."
      )
    end
  end
end
