require "spec_helper"

describe Mongoid::LogSubscriber do

  describe ".query" do

    let!(:subscribe) do
      Mongoid::LogSubscriber.log_subscribers.first
    end

    before do
      @old_level, Moped.logger.level = Moped.logger.level, 0
    end

    after do
      Moped.logger.level = @old_level
    end

    context "when quering the database" do

      it "logs the operation" do
        expect(subscribe).to receive(:debug).once
        Band.all.to_a
      end
    end

    context "when creating a new subscriber" do

      class TestLogSubscriber < ActiveSupport::LogSubscriber
        attr_reader :debugs

        def initialize
          @debugs = []
        end

        def query(event)
          @debugs << event
        end

        def logger
          Moped.logger
        end
      end

      let(:test_subscriber) do
        TestLogSubscriber.new
      end

      before do
        ActiveSupport::LogSubscriber.attach_to :moped, test_subscriber
      end

      after do
        TestLogSubscriber.log_subscribers.pop
      end

      it "pushes the new log subscriber" do
        expect(Mongoid::LogSubscriber.subscribers.last).to be_a TestLogSubscriber
      end

      context "when quering the database" do

        before do
          expect(subscribe).to receive(:debug).once
          PetOwner.all.to_a
        end

        it "sends operations logs to TestLogSubscriber" do
          expect(test_subscriber.debugs.size).to eq(1)
        end
      end
    end
  end
end
