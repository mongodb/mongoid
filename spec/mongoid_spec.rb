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

  describe ".unit_of_work" do

    context "when an exception is raised" do

      let(:person) do
        Person.new
      end

      before do
        Mongoid::IdentityMap.set(person)

        begin
          Mongoid.unit_of_work do
            raise RuntimeError
          end
        rescue
        end
      end

      let(:identity_map) do
        Mongoid::Threaded.identity_map
      end

      it "clears the identity map" do
        identity_map.should be_empty
      end
    end

    context "when no exception is raised" do

      let(:person) do
        Person.new
      end

      before do
        Mongoid::IdentityMap.set(person)
        Mongoid.unit_of_work {}
      end

      let(:identity_map) do
        Mongoid::Threaded.identity_map
      end

      it "clears the identity map" do
        identity_map.should be_empty
      end
    end
  end
end
