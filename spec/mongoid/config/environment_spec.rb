require "spec_helper"

describe Mongoid::Config::Environment do

  after(:all) do
    Rails = RailsTemp
    Object.send(:remove_const, :RailsTemp)
  end

  describe "#env_name" do

    context "when using rails" do

      before do
        module Rails
          class << self
            def env; "production"; end
          end
        end
      end

      after do
        RailsTemp = Rails
        Object.send(:remove_const, :Rails)
      end

      it "returns the rails environment" do
        described_class.env_name.should eq("production")
      end
    end

    context "when using sinatra" do

      before do
        module Sinatra
          module Base
            extend self
            def environment; :staging; end
          end
        end
      end

      after do
        Object.send(:remove_const, :Sinatra)
      end

      it "returns the sinatra environment" do
        described_class.env_name.should eq("staging")
      end
    end

    context "when the rack env variable is defined" do

      before do
        ENV["RACK_ENV"] = "acceptance"
      end

      after do
        ENV["RACK_ENV"] = nil
      end

      it "returns the rack environment" do
        described_class.env_name.should eq("acceptance")
      end
    end

    context "when no environment information is found" do

      it "raises an error" do
        expect { described_class.env_name }.to raise_error(
          Mongoid::Errors::NoEnvironment
        )
      end
    end
  end

  describe "#load_yaml" do
    let(:file) do
      File.join(File.dirname(__FILE__), "../..", "config", "mongoid.yml")
    end

    it 'return an Hash if env unknow' do
      described_class.load_yaml(file, :unknown).should == {}
    end

    it 'return a with indifferent_access' do
      described_class.load_yaml(file, :test).should be_a(HashWithIndifferentAccess)
    end
  end
end
