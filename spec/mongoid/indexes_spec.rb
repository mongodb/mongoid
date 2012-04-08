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
      klass.index_options.should eq({})
    end
  end

  describe ".remove_indexes" do

    let(:klass) do
      Person
    end

    let(:collection) do
      klass.collection
    end

    before do
      klass.create_indexes
      klass.remove_indexes
    end

    it "removes the indexes" do
      collection.indexes.reject{ |doc| doc["name"] == "_id_" }.should be_empty
    end
  end

  describe ".create_indexes" do

    let(:klass) do
      Class.new do
        include Mongoid::Document
        store_in collection: "test_class"
        index _type: 1, options: { unique: false, background: true }
      end
    end

    before do
      klass.create_indexes
    end

    it "creates the indexes" do
      klass.collection.indexes[_type: 1].should_not be_nil
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
        klass.index_options[_type: 1].should eq(
          { unique: false, background: true }
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

    context "when providing unique options" do

      before do
        klass.index(name: 1, options: { unique: true })
      end

      let(:options) do
        klass.index_options[name: 1]
      end

      it "sets the index with unique options" do
        options.should eq(unique: true)
      end
    end

    context "when providing a drop_dups option" do

      before do
        klass.index(name: 1, options: { drop_dups: true })
      end

      let(:options) do
        klass.index_options[name: 1]
      end

      it "sets the index with dropDups options" do
        options.should eq(dropDups: true)
      end
    end

    context "when providing a sparse option" do

      before do
        klass.index(name: 1, options: { sparse: true })
      end

      let(:options) do
        klass.index_options[name: 1]
      end

      it "sets the index with sparse options" do
        options.should eq(sparse: true)
      end
    end

    context "when providing a name option" do

      before do
        klass.index(name: 1, options: { name: "index_name" })
      end

      let(:options) do
        klass.index_options[name: 1]
      end

      it "sets the index with name options" do
        options.should eq(name: "index_name")
      end
    end

    context "when providing a background option" do

      before do
        klass.index(name: 1, options: { background: true })
      end

      let(:options) do
        klass.index_options[name: 1]
      end

      it "sets the index with background options" do
        options.should eq(background: true)
      end
    end

    context "when providing a compound index" do

      before do
        klass.index(name: 1, title: -1)
      end

      let(:options) do
        klass.index_options[name: 1, title: -1]
      end

      it "sets the compound key index" do
        options.should be_empty
      end
    end

    context "when providing a geospacial index" do

      before do
        klass.index(location: "2d")
      end

      let(:options) do
        klass.index_options[location: "2d"]
      end

      it "sets the geospacial index" do
        options.should be_empty
      end
    end

    context "when providing an invalid option" do

      it "raises an error" do
        expect {
          klass.index(name: 1, options: { invalid: true })
        }.to raise_error(Mongoid::Errors::InvalidIndex)
      end
    end

    context "when providing an invalid spec" do

      context "when the spec is not a hash" do

        it "raises an error" do
          expect {
            klass.index(:name)
          }.to raise_error(Mongoid::Errors::InvalidIndex)
        end
      end

      context "when the spec key is invalid" do

        it "raises an error" do
          expect {
            klass.index(name: "something")
          }.to raise_error(Mongoid::Errors::InvalidIndex)
        end
      end
    end
  end
end
