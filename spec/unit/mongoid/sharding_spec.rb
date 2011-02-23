require "spec_helper"

describe Mongoid::Sharding do

  describe ".included" do

    before do
      @class = Class.new do
        include Mongoid::Sharding
      end
    end

    it "adds an shard_key_fields accessor" do
      @class.should respond_to(:shard_key_fields)
    end

    it "defaults shard_key_fields to an empty array" do
      @class.shard_key_fields.should == []
    end

  end

  describe ".shard_key" do

    before do
      @class = Class.new do
        include Mongoid::Sharding
      end
    end

    it "specifies a shard key on the collection" do
      @class.shard_key(:name)
      @class.shard_key_fields.should == [:name]
    end

  end
  
  describe ".shard_key_selector" do
    
    before do
      @class = Class.new do
        include Mongoid::Sharding
        attr_accessor :name
      end
    end
    
    it "creates a hash of shard key field names mapped to values" do
      @class.shard_key(:name)
      jo = @class.new
      jo.name = 'Jo'
      jo.shard_key_selector.should == { 'name' => 'Jo' }
    end
    
  end

end
