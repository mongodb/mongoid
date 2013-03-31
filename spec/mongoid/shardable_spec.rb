require "spec_helper"

describe Mongoid::Shardable do

  describe ".included" do

    let(:klass) do
      Class.new do
        include Mongoid::Shardable
      end
    end

    it "adds an shard_key_fields accessor" do
      expect(klass).to respond_to(:shard_key_fields)
    end

    it "defaults shard_key_fields to an empty array" do
      expect(klass.shard_key_fields).to be_empty
    end
  end

  describe ".shard_key" do

    let(:klass) do
      Class.new do
        include Mongoid::Shardable
      end
    end

    before do
      klass.shard_key(:name)
    end

    it "specifies a shard key on the collection" do
      expect(klass.shard_key_fields).to eq([:name])
    end
  end

  describe "#shard_key_selector" do

    let(:klass) do
      Class.new do
        include Mongoid::Shardable
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
      expect(object.shard_key_selector).to eq({ "name" => "Jo" })
    end
  end
end
