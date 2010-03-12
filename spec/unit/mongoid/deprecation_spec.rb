require "spec_helper"

describe Mongoid::Deprecation do

  let(:logger) do
    stub.quacks_like(Logger.allocate)
  end

  before do
    Logger.expects(:new).with($stdout).returns(logger)
  end

  describe "#alert" do

    let(:deprecation) do
      Mongoid::Deprecation.instance
    end

    it "calls warn on the memoized logger" do
      logger.expects(:warn).with("Deprecation: testing")
      deprecation.alert("testing")
    end
  end
end
