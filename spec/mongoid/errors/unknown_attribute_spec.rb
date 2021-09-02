# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::UnknownAttribute do

  describe "#message" do

    let(:error) do
      described_class.new(Person, :gender)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Attempted to set a value for 'gender' which is not allowed on"
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "Person#gender= was called but there is no 'gender'"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Define the field 'gender' in Person, or include"
      )
    end
  end
end
