require "spec_helper"

describe Mongoid::Errors::InvalidScope do

  describe "#message" do

    let(:error) do
      described_class.new(Band, {})
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Defining a scope of value {} on Band is not allowed."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Scopes in Mongoid must be either criteria objects or procs that wrap"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Change the scope to be a criteria or proc wrapped critera."
      )
    end
  end
end
