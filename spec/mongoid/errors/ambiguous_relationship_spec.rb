# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Errors::AmbiguousRelationship do

  describe "#message" do

    let(:error) do
      described_class.new(Person, Drug, :person, [ :drugs, :evil_drugs ])
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Ambiguous associations :drugs, :evil_drugs defined on Person."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "When Mongoid attempts to set an inverse document of an association in memory"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "On the :person association on Drug you must add an :inverse_of option"
      )
    end
  end
end
