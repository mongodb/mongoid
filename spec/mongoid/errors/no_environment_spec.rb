require "spec_helper"

describe Mongoid::Errors::NoEnvironment do

  describe "#message" do

    let(:error) do
      described_class.new
    end

    it "returns the no environment message" do
      error.message.should eq(
        "Mongoid attempted to find the appropriate environment but no " +
        "Rails.env, Sinatra::Base.environment, RACK_ENV, or MONGOID_ENV could be found."
      )
    end
  end
end
