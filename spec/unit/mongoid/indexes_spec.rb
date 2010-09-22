require "spec_helper"

describe Mongoid::Indexes do

  describe ".included" do

    before do
      @class = Class.new do
        include Mongoid::Indexes
      end
    end

    it "adds an index_options accessor" do
      @class.should respond_to(:index_options)
    end

    it "defaults index_options to empty hash" do
      @class.index_options.should == {}
    end

  end

  describe ".create_indexes" do
    before do
      @collection = mock

      @class = Class.new do
        include Mongoid::Indexes

        def self.index_options
          {:_type => {:unique => false, :background => true}}
        end
      end
    end

    it "creates the indexes" do
      @class.expects(:_collection).returns(@collection)
      @collection.expects(:create_index).with(:_type, {:unique => false, :background => true})
      @class.create_indexes
    end
  end

  describe ".add_indexes" do

    context "when indexes have not been added" do

      before do
        @class = Class.new do
          include Mongoid::Indexes
          def self.hereditary?
            true
          end
        end
      end

      it "adds the _type index" do
        @class.add_indexes
        @class.index_options[:_type].should == {:unique => false, :background => true}
      end

    end

    context "when indexes have been added" do

      before do
        @class = Class.new do
          include Mongoid::Indexes
          def self.hereditary?
            true
          end
        end
        @class.index_options = {:type => {:unique => false, :background => true}}
      end

      it "ignores the request" do
        @class.add_indexes
      end

    end

  end

  describe ".index" do

    before do
      @class = Class.new do
        include Mongoid::Indexes
      end
    end

    context "when unique" do

      it "creates a unique index on the collection" do
        @class.index(:name, :unique => true)
        @class.index_options[:name].should == {:unique => true}
      end

    end

    context "when not unique" do
      it "creates an index on the collection" do
        @class.index(:name)
        @class.index_options[:name].should == {:unique => false}
      end

    end

  end

end
