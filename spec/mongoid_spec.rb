require "spec_helper"

describe Mongoid do

  describe ".configure" do

    context "when no block supplied" do

      it "returns the config singleton" do
        Mongoid.configure.should eq(Mongoid::Config)
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

  describe ".default_session" do

    it "returns the default session" do
      Mongoid.default_session.should eq(Mongoid::Sessions.default)
    end
  end

  describe ".session" do

    it "returns the named session" do
      Mongoid.session(:default).should eq(Mongoid::Sessions.default)
    end
  end
end
