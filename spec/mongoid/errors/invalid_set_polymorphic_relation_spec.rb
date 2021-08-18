# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidSetPolymorphicRelation do

  describe "#message" do

    let(:error) do
      described_class.new(:postable, Post, Person)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "The postable attribute can't be set to an instance of Person"
      )
    end
  end
end
