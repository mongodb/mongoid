require "spec_helper"

describe Mongoid::Errors::NoMapReduceOutput do

  describe "#message" do

    let(:error) do
      described_class.new(query: {})
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "No output location was specified for the map/reduce operation."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "When executing a map/reduce, you must provide the output location"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Provide the location that the output of the operation"
      )
    end
  end
end
