require "spec_helper"

describe Mongoid::Errors::InvalidSetPolymorphicRelation do

  describe "#message" do

    let(:error) do
      described_class.new(:eyeable, Eye, Face)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "The eyeable attribute can't be set to an instance of Face"
      )
    end
  end
end
