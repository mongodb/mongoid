require "spec_helper"

describe Mongoid::Collections::Retry do

  class SomeCollection
    include Mongoid::Collections::Retry

    def perform
      retry_on_connection_failure do
        do_action
      end
    end

    def do_action
      "do something here"
    end
  end

  subject { SomeCollection.new }

  let(:logger) { stub.quacks_like(Logger.allocate) }

  before do
    logger.expects(:warn).at_least(0)
    Mongoid.stubs(:logger => logger)
  end

  describe "when a connection failure occurs" do

    before do
      subject.expects(:do_action).raises(Mongo::ConnectionFailure).times(max_retries + 1)
    end

    describe "and Mongoid.max_retries_on_connection_failure is 0" do

      let :max_retries do
        0
      end

      it "raises Mongo::ConnectionFailure" do
        expect { subject.perform }.to raise_error(Mongo::ConnectionFailure)
      end
    end

    describe "and Mongoid.max_retries_on_connection_failure is greater than 0" do

      let :max_retries do
        2
      end

      before do
        Mongoid.max_retries_on_connection_failure = max_retries
      end

      after do
        Mongoid.max_retries_on_connection_failure = 0
      end

      it "raises Mongo::ConnectionFailure" do
        expect { subject.perform }.to raise_error(Mongo::ConnectionFailure)
      end
    end
  end

  describe "when a connection failure occurs and it comes back after a few retries" do

    let :result do
      'something'
    end

    before do
      subject.stubs(:do_action).raises(Mongo::ConnectionFailure).then.returns(result)
    end

    describe "and Mongoid.max_retries_on_connection_failure is 0" do

      let :max_retries do
        0
      end

      it "raises Mongo::ConnectionFailure" do
        expect { subject.perform }.to raise_error(Mongo::ConnectionFailure)
      end
    end

    describe "and Mongoid.max_retries_on_connection_failure is greater than 0" do

      let :max_retries do
        2
      end

      before do
        Mongoid.max_retries_on_connection_failure = max_retries
      end

      after do
        Mongoid.max_retries_on_connection_failure = 0
      end

      it "should not raise Mongo::ConnectionFailure" do
        expect { subject.perform }.to_not raise_error(Mongo::ConnectionFailure)
      end

      it "should return the result of the command" do
        subject.perform.should == result
      end

      it "sends warning message to logger on retry attempts" do
        logger.expects(:warn).with { |value| value =~ /1/ }
        subject.perform
      end
    end
  end

  describe "when an operation failure occurs" do

    context "because the primary server has changed" do

      before do
        subject.expects(:do_action).raises(Mongo::OperationFailure.new("10054: not master")).times(max_retries + 1)
      end

      describe "and Mongoid.max_retries_on_connection_failure is 0" do

        let :max_retries do
          0
        end

        it "raises Mongo::OperationFailure" do
          expect { subject.perform }.to raise_error(Mongo::OperationFailure)
        end
      end

      describe "and Mongoid.max_retries_on_connection_failure is greater than 0" do

        let :max_retries do
          2
        end

        before do
          Mongoid.max_retries_on_connection_failure = max_retries
        end

        after do
          Mongoid.max_retries_on_connection_failure = 0
        end

        it "raises Mongo::OperationFailure" do
          expect { subject.perform }.to raise_error(Mongo::OperationFailure)
        end
      end
    end


    context "because the primary server has changed and it comes back after a few retries" do
      let :result do
        'something'
      end

      before do
        subject.stubs(:do_action).raises(Mongo::OperationFailure.new("10054: not master")).then.returns(result)
      end

      describe "and Mongoid.max_retries_on_connection_failure is 0" do

        let :max_retries do
          0
        end

        it "raises Mongo::OperationFailure" do
          expect { subject.perform }.to raise_error(Mongo::OperationFailure)
        end
      end

      describe "and Mongoid.max_retries_on_connection_failure is greater than 0" do

        let :max_retries do
          2
        end

        before do
          Mongoid.max_retries_on_connection_failure = max_retries
        end

        after do
          Mongoid.max_retries_on_connection_failure = 0
        end

        it "should not raise Mongo::ConnectionFailure" do
          expect { subject.perform }.to_not raise_error(Mongo::OperationFailure)
        end

        it "should return the result of the command" do
          subject.perform.should == result
        end

        it "sends warning message to logger on retry attempts" do
          logger.expects(:warn).with { |value| value =~ /1/ }
          subject.perform
        end
      end
    end

    context "because some other error occurs" do
      before do
        subject.stubs(:do_action).raises(Mongo::OperationFailure.new("some other error"))
      end

      it "raises Mongo::OperationFailure" do
        expect { subject.perform }.to raise_error(Mongo::OperationFailure)
      end
    end
  end

end
