require "spec_helper"

describe Mongoid::Errors::UnknownAttribute do

  describe "#message" do

    let(:error) do
      described_class.new(Person, :gender)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Attempted to set a value for 'gender' which is not allowed on"
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Without including Mongoid::Attributes::Dynamic in your model"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "You can include Mongoid::Attributes::Dynamic"
      )
    end
  end
end
