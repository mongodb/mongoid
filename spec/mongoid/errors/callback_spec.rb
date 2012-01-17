require "spec_helper"

describe Mongoid::Errors::Callback do

  describe "#message" do

    let(:error) do
      described_class.new(Post, :create!)
    end

    it "returns the warning of callback returning false" do
      error.message.should include(
        "Calling create! on Post resulted in a false return from a callback."
      )
    end
  end
end
