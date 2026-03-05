# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Errors::AttributeNotLoaded do

  describe "#message" do

    let(:error) do
      described_class.new(Band, :label)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Attempted to access attribute 'label' on Band which was not loaded."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "You loaded an instance of Band using a query projection method"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Ensure your query projection methods such as `.only` and `.without`"
      )
    end
  end
end
