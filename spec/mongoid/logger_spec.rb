require "spec_helper"

describe Mongoid::Logger do

  let(:logger) do
    described_class.new
  end

  before(:all) do
    Mongoid.logger = ::Logger.new($stdout)
  end

  after(:all) do
    Mongoid.logger = nil
  end

  describe ".logger" do

    it "returns Mongoid's configured logger" do
      logger.logger.should be_a(Logger)
    end
  end

  context "log_levels" do

    log_levels = %w(info debug warn error fatal)

    context "with a logger set" do

      log_levels.each do |log_level|

        it "#{log_level} delegates to the configured logger" do
          logger.send(log_level.to_sym, "message")
        end
      end
    end

    context "with a nil logger" do

      before do
        Mongoid.logger = nil
      end

      log_levels.each do |log_level|

        it "#{log_level} does nothing" do
          expect { subject.send(log_level.to_sym, "message") }.to_not raise_error
        end
      end
    end
  end
end
