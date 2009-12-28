require "spec_helper"

describe Mongoid::Config do

  after :all do
    config.raise_not_found_error = true
  end

  let(:config) { Mongoid::Config.instance }

  describe ".database=" do

    context "when object provided is not a Mongo::DB" do

      it "raises an error" do
        lambda { config.database = "Test" }.should raise_error
      end

    end

  end

  describe ".raise_not_found_error=" do

    context "when setting to true" do

      before do
        config.raise_not_found_error = true
      end

      it "sets the value" do
        config.raise_not_found_error.should == true
      end

    end

    context "when setting to false" do

      before do
        config.raise_not_found_error = false
      end

      it "sets the value" do
        config.raise_not_found_error.should == false
      end

    end

  end

end
