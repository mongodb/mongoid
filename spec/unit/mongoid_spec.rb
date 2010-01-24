require "spec_helper"

describe Mongoid do

  describe ".config" do

    context "when no block supplied" do

      it "returns the config singleton" do
        Mongoid.config.should == Mongoid::Config.instance
      end

    end

    context "when a block is supplied" do

      before do
        Mongoid.config do |config|
          config.allow_dynamic_fields = false
        end
      end

      after do
        Mongoid.config do |config|
          config.allow_dynamic_fields = true
        end
      end

      it "sets the values on the config instance" do
        Mongoid.allow_dynamic_fields.should be_false
      end

    end

  end

end
