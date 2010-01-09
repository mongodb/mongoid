require "spec_helper"

describe Mongoid::Indexes do

  describe ".included" do

    before do
      @class = Class.new do
        include Mongoid::Indexes
      end
    end

    it "adds an indexed accessor" do
      @class.should respond_to(:indexed)
    end

    it "defaults indexed to false" do
      @class.indexed.should be_false
    end

  end

  describe ".add_indexes" do

    before do
      @collection = mock
    end

    context "when indexes have not been added" do

      before do
        @class = Class.new do
          include Mongoid::Indexes
        end
      end

      it "adds the _type index" do
        @class.expects(:_collection).returns(@collection)
        @collection.expects(:create_index).with(:_type, false)
        @class.add_indexes
        @class.indexed.should be_true
      end

    end

    context "when indexes have been added" do

      before do
        @class = Class.new do
          include Mongoid::Indexes
        end
        @class.indexed = true
      end

      it "ignores the request" do
        @class.add_indexes
      end

    end

  end

  describe ".index" do

    before do
      @collection = mock
      @class = Class.new do
        include Mongoid::Indexes
      end
      @class.expects(:collection).returns(@collection)
    end

    context "when unique" do

      it "creates a unique index on the collection" do
        @collection.expects(:create_index).with(:name, true)
        @class.index(:name, :unique => true)
      end

    end

    context "when not unique" do

      it "creates an index on the collection" do
        @collection.expects(:create_index).with(:name, false)
        @class.index(:name)
      end

    end

  end

end
