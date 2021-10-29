# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::NestedAttributesMetadataNotFound do

  describe "#message" do

    let(:error) do
      described_class.new(Person, :posts)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Could not find metadata for association 'posts' on model: Person."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "When defining nested attributes for an association, Mongoid needs"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Make sure that there is an association defined named 'posts' on Person"
      )
    end
  end
end
