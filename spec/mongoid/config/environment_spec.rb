require "spec_helper"

describe Mongoid::Config::Environment do

  after(:all) do
    Rails = RailsTemp
    Object.send(:remove_const, :RailsTemp)
  end

  describe "#env_name" do

    context "when using rails" do

      context "when an environment exists" do

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
          expect(described_class.env_name).to eq("production")
        end
      end
    end

    context "when using sinatra" do

      before do
        Object.send(:remove_const, :Rails) if defined?(Rails)

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
        expect(described_class.env_name).to eq("staging")
      end
    end

    context "when the rack env variable is defined" do

      before do
        Object.send(:remove_const, :Rails) if defined?(Rails)
        ENV["RACK_ENV"] = "acceptance"
      end

      after do
        ENV["RACK_ENV"] = nil
      end

      it "returns the rack environment" do
        expect(described_class.env_name).to eq("acceptance")
      end
    end

    context "when no environment information is found" do

      before do
        Object.send(:remove_const, :Rails) if defined?(Rails)
      end

      it "raises an error" do
        expect { described_class.env_name }.to raise_error(
          Mongoid::Errors::NoEnvironment
        )
      end
    end
  end
end
