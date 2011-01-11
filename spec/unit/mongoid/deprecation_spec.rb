require "spec_helper"

describe Mongoid::Deprecation do

  let(:logger) do
    stub.quacks_like(Logger.allocate)
  end

  before do
    Mongoid::Logger.expects(:new).returns(logger)
  end

  after(:all) do
    Mongoid::Deprecation.instance_variable_set(:@logger, Mongoid::Logger.new)
  end

  describe "#alert" do

    it "calls warn on the memoized logger" do
      logger.expects(:warn).with("Deprecation: testing")
      described_class.alert("testing")
    end
  end
end
