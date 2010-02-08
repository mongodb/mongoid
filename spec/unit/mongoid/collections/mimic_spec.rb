require "spec_helper"

describe Mongoid::Collections::Mimic do

  let(:mimic) do
    klass = Class.new do
      include Mongoid::Collections::Mimic
    end
    klass.new
  end

  describe "#attempt" do

    before do
      @operation = stub.quacks_like(Proc.new {})
    end

    context "when the call succeeds" do

      it "returns the value" do
        @operation.expects(:call).returns([])
        mimic.attempt(@operation, Time.now).should == []
      end
    end

    context "when the call fails" do

      before do
        Mongoid.reconnect_time = 0.10
      end

      after do
        Mongoid.reconnect_time = 3
      end

      it "retries the call" do
        @operation.expects(:call).at_least_once.raises(Mongo::ConnectionFailure.new)
        lambda { mimic.attempt(@operation, Time.now) }.should raise_error
      end
    end

  end
end
