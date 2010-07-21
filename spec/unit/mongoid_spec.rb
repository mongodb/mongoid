require "spec_helper"

describe Mongoid do

  describe ".configure" do

    context "when no block supplied" do

      it "returns the config singleton" do
        Mongoid.configure.should == Mongoid::Config.instance
      end
    end

    context "when a block is supplied" do

      before do
        Mongoid.configure do |config|
          config.allow_dynamic_fields = false
        end
      end

      after do
        Mongoid.configure do |config|
          config.allow_dynamic_fields = true
        end
      end

      it "sets the values on the config instance" do
        Mongoid.allow_dynamic_fields.should be_false
      end
    end
  end

  describe ".deprecate" do
    let(:deprecation) { stub }

    before do
      Mongoid::Deprecation.expects(:instance).returns(deprecation)
    end

    it "calls alert on the deprecation singleton" do
      deprecation.expects(:alert).with("testing")
      Mongoid.deprecate("testing")
    end
  end
end
