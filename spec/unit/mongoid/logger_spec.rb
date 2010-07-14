require "spec_helper"

describe Mongoid::Logger do
  describe ".logger" do
    it "returns Mongoid's configured logger" do
      Mongoid.expects(:logger)
      subject.logger
    end
  end

  context "log_levels" do
    log_levels = %w(info debug warn error fatal)

    context "with a logger set" do
      let(:logger) { stub.quacks_like(Logger.allocate) }
      log_levels.each do |log_level|
        before do
          subject.stubs(:logger => logger)
        end
        it "#{log_level} delegates to the configured logger" do
          logger.expects(log_level).with("message")
          subject.send(log_level.to_sym, "message")
        end
      end
    end

    context "with a nil logger" do
      log_levels.each do |log_level|
        before do
          subject.stubs(:logger => nil)
        end
        it "#{log_level} does nothing" do
          expect { subject.send(log_level.to_sym, "message") }.to_not raise_error
        end
      end
    end
  end
end
