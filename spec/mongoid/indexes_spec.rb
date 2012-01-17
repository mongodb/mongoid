require "spec_helper"

describe Mongoid::Indexes do

  describe ".included" do

    let(:klass) do
      Class.new do
        include Mongoid::Indexes
      end
    end

    it "adds an index_options accessor" do
      klass.should respond_to(:index_options)
    end

    it "defaults index_options to empty hash" do
      klass.index_options.should == {}
    end
  end

  describe ".create_indexes" do

    let(:klass) do
      Class.new do
        include Mongoid::Document
        store_in :test_class

        def self.index_options
          { :_type => { :unique => false, :background => true }}
        end
      end
    end

    before do
      klass.create_indexes
    end

    it "creates the indexes" do
      klass.index_information["_type_1"].should_not be_nil
    end
  end

  describe ".add_indexes" do

    context "when indexes have not been added" do

      let(:klass) do
        Class.new do
          include Mongoid::Indexes
          def self.hereditary?
            true
          end
        end
      end

      before do
        klass.add_indexes
      end

      it "adds the _type index" do
        klass.index_options[:_type].should eq(
          { :unique => false, :background => true }
        )
      end
    end
  end

  describe ".index" do

    let(:klass) do
      Class.new do
        include Mongoid::Indexes
      end
    end

    context "when unique" do

      before do
        klass.index(:name, :unique => true)
      end

      it "creates a unique index on the collection" do
        klass.index_options[:name].should == {:unique => true}
      end
    end

    context "when not unique" do

      before do
        klass.index(:name)
      end

      it "creates an index on the collection" do
        klass.index_options[:name].should == {:unique => false}
      end
    end
  end
end
