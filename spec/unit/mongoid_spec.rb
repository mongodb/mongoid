require "spec_helper"

describe Mongoid do

  describe ".method_missing" do

    before do
      @config = mock
      Mongoid::Config.expects(:instance).returns(@config)
    end

    it "delegates all calls to the config singleton" do
      @config.expects(:raise_not_found_error=).with(false)
      Mongoid.raise_not_found_error = false
    end

  end

end
