require "spec_helper"

describe Mongoid::Loggable do

  describe "#logger=" do

    let(:logger) do
      Logger.new($stdout).tap do |log|
        log.level = Logger::INFO
      end
    end

    before do
      Mongoid.logger = logger
    end

    it "sets the logger" do
      Mongoid.logger.should eq(logger)
    end
  end
end
