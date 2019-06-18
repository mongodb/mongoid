# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Errors::NoParent do

  describe "#message" do

    let(:error) do
      described_class.new(Address)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Cannot persist embedded document Address without a parent document."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "If the document is embedded, in order to be persisted it must"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Ensure that you've set the parent association if instantiating"
      )
    end
  end
end
