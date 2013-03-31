require "spec_helper"

describe Mongoid::Errors::UnsavedDocument do

  describe "#message" do

    let(:base) do
      Person.new
    end

    let(:document) do
      Post.new
    end

    let(:error) do
      described_class.new(base, document)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Attempted to save Post before the parent Person."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "You cannot call create or create! through the relation"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Make sure to only use create or create!"
      )
    end
  end
end
