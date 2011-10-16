require "spec_helper"

describe Mongoid::Config do

  before(:all) do
    described_class.logger = nil
  end

  describe "#logger=" do

    let(:config) do
      described_class
    end

    after do
      config.logger = nil
    end

    context "when provided false" do

      before do
        config.logger = false
      end

      it "does not set the logger" do
        config.logger.should be_nil
      end
    end

    context "when provided true" do

      before do
        config.logger = true
      end

      it "sets the default logger" do
        config.logger.should be_a(::Logger)
      end
    end

    context "when provided nil" do

      before do
        config.logger = nil
      end

      it "does not set the logger" do
        config.logger.should be_nil
      end
    end

    context "when provided a logger" do

      let(:logger) do
        ::Logger.new($stdout)
      end

      before do
        config.logger = logger
      end

      it "sets the logger" do
        config.logger.should eq(logger)
      end
    end

    context "when provided an object that quacks like a logger" do

      let(:logger) do
        stub.quacks_like(::Logger.allocate)
      end

      before do
        config.logger = logger
      end

      it "sets the logger" do
        config.logger.should eq(logger)
      end
    end

    context "when provided an object that does not quack like a logger" do

      let(:logger) do
        stub
      end

      before do
        logger.expects(:respond_to?).with(:info).returns(false)
        config.logger = logger
      end

      it "does not the logger" do
        config.logger.should be_nil
      end
    end
  end
end
