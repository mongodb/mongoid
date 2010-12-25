require "spec_helper"

describe Mongoid do

  describe ".configure" do

    context "when no block supplied" do

      it "returns the config singleton" do
        Mongoid.configure.should == Mongoid::Config
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

    it "returns true" do
      Mongoid.deprecate("testing").should be_true
    end
  end
end
