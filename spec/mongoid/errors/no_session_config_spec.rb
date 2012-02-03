require "spec_helper"

describe Mongoid::Errors::NoSessionConfig do

  describe "#message" do

    let(:error) do
      described_class.new(:secondary)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "No configuration could be found for a session named 'secondary'."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "When attempting to create the new session, Mongoid could not find a session"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Double check your mongoid.yml to make sure under the sessions"
      )
    end
  end
end
