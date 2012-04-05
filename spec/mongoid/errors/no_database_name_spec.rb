require "spec_helper"

describe Mongoid::Errors::NoDatabaseName do

  describe "#message" do

    let(:error) do
      described_class.new(:default, { session: "default" })
    end

    it "contains the problem in the message" do
      error.message.should include(
        "No name provided for database configuration: :default."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Each database configuration must provide a name so"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "If configuring via a mongoid.yml, ensure that within your :default"
      )
    end
  end
end
