require "spec_helper"

describe Mongoid::Sharding do

  describe ".included" do

    let(:klass) do
      Class.new do
        include Mongoid::Sharding
      end
    end

    it "adds an shard_key_fields accessor" do
      klass.should respond_to(:shard_key_fields)
    end

    it "defaults shard_key_fields to an empty array" do
      klass.shard_key_fields.should == []
    end
  end

  describe ".shard_key" do

    let(:klass) do
      Class.new do
        include Mongoid::Sharding
      end
    end

    before do
      klass.shard_key(:name)
    end

    it "specifies a shard key on the collection" do
      klass.shard_key_fields.should == [:name]
    end
  end

  describe "#shard_key_selector" do

    let(:klass) do
      Class.new do
        include Mongoid::Sharding
        attr_accessor :name
      end
    end

    let(:object) do
      klass.new
    end

    before do
      klass.shard_key(:name)
      object.name = "Jo"
    end

    it "returns a hash of shard key names and values" do
      object.shard_key_selector.should == { "name" => "Jo" }
    end
  end
end
