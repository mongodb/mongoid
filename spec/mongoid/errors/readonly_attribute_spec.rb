# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::ReadonlyAttribute do

  describe "#message" do

    let(:error) do
      described_class.new(:title, "mr")
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Attempted to set the readonly attribute 'title' with the value: mr."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Attributes flagged as readonly via Model.attr_readonly can only"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Don't define 'title' as readonly, or do not attempt to update"
      )
    end
  end
end
