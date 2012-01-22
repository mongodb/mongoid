require "spec_helper"

describe Mongoid::Errors::UnknownAttribute do

  describe "#message" do

    let(:error) do
      described_class.new(Person, :gender)
    end

    it "returns the message with model and attribute information" do
      error.message.should eq(
        "Attempted to set a value for 'gender' on the model Person, which " +
        "has no field defined for it and allow_dynamic_fields is false."
      )
    end
  end
end
