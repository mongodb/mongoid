require "spec_helper"

describe Mongoid::Errors::NestedAttributesMetadataNotFound do

  describe "#message" do

    let(:error) do
      described_class.new(Person, :posts)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Could not find metadata for relation 'posts' on model: Person."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "When defining nested attributes for a relation, Mongoid needs"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Make sure that there is a relation defined named 'posts' on Person"
      )
    end
  end
end
