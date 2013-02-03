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

    context "when no database specific options exist" do

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

    context "when database specific options exist" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
          store_in collection: "test_db_remove"
          index({ test: 1 }, { database: "mia_2" })
          index({ name: 1 }, { background: true })
        end
      end

      before do
        klass.create_indexes
        klass.remove_indexes
      end

      let(:indexes) do
        klass.with(database: "mia_2").collection.indexes
      end

      it "creates the indexes" do
        indexes.reject{ |doc| doc["name"] == "_id_" }.should be_empty
      end
    end
  end

  describe ".create_indexes" do

    context "when no database options are specified" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
          store_in collection: "test_class"
          index({ _type: 1 }, { unique: false, background: true })
        end
      end

      before do
        klass.create_indexes
      end

      it "creates the indexes" do
        klass.collection.indexes[_type: 1].should_not be_nil
      end
    end

    context "when database options are specified" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
          store_in collection: "test_db_indexes"
          index({ _type: 1 }, { database: "mia_1" })
        end
      end

      before do
        klass.create_indexes
      end

      let(:indexes) do
        klass.with(database: "mia_1").collection.indexes
      end

      it "creates the indexes" do
        indexes[_type: 1].should_not be_nil
      end
    end
  end

  describe ".add_indexes" do

    context "when indexes have not been added" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
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
        include Mongoid::Document
        field :a, as: :authentication_token
      end
    end

    context "when indexing a field that is aliased" do

      before do
        klass.index({ authentication_token: 1 }, { unique: true })
      end

      let(:options) do
        klass.index_options[a: 1]
      end

      it "sets the index with unique options" do
        options.should eq(unique: true)
      end
    end

    context "when providing unique options" do

      before do
        klass.index({ name: 1 }, { unique: true })
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
        klass.index({ name: 1 }, { drop_dups: true })
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
        klass.index({ name: 1 }, { sparse: true })
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
        klass.index({ name: 1 }, { name: "index_name" })
      end

      let(:options) do
        klass.index_options[name: 1]
      end

      it "sets the index with name options" do
        options.should eq(name: "index_name")
      end
    end

    context "when providing database options" do

      before do
        klass.index({ name: 1 }, { database: "mongoid_index_alt" })
      end

      let(:options) do
        klass.index_options[name: 1]
      end

      it "sets the index with background options" do
        options.should eq(database: "mongoid_index_alt")
      end
    end

    context "when providing a background option" do

      before do
        klass.index({ name: 1 }, { background: true })
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
        klass.index({ name: 1, title: -1 })
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
        klass.index({ location: "2d" }, { min: -200, max: 200, bits: 32 })
      end

      let(:options) do
        klass.index_options[location: "2d"]
      end

      it "sets the geospacial index" do
        options.should eq({ min: -200, max: 200, bits: 32 })
      end
    end

    context "when providing a geo haystack index" do

      before do
        klass.index({ location: "geoHaystack" }, { min: -200, max: 200, bucket_size: 0.5 })
      end

      let(:options) do
        klass.index_options[location: "geoHaystack"]
      end

      it "sets the geo haystack index" do
        options.should eq({ min: -200, max: 200, bucketSize: 0.5 })
      end
    end

    context "when providing a Spherical Geospatial index" do

      before do
        klass.index({ location: "2dsphere" })
      end

      let(:options) do
        klass.index_options[location: "2dsphere"]
      end

      it "sets the spherical geospatial index" do
        options.should be_empty
      end
    end

    context "when providing a hashed index" do

      before do
        klass.index({ a: "hashed" })
      end

      let(:options) do
        klass.index_options[a: "hashed"]
      end

      it "sets the hashed index" do
        options.should be_empty
      end
    end

    context "when providing a text index" do

      before do
        klass.index({ content: "text" })
      end

      let(:options) do
        klass.index_options[content: "text"]
      end

      it "sets the text index" do
        options.should be_empty
      end
    end

    context "when providing a compound text index" do

      before do
        klass.index({ content: "text", title: "text" }, { weights: { content: 1, title: 2 } })
      end

      let(:options) do
        klass.index_options[content: "text", title: "text"]
      end

      it "sets the compound text index" do
        options.should eq(weights: { content: 1, title: 2 })
      end
    end

    context "when providing an expire_after_seconds option" do

      before do
        klass.index({ name: 1 }, { expire_after_seconds: 3600 })
      end

      let(:options) do
        klass.index_options[name: 1]
      end

      it "sets the index with sparse options" do
        options.should eq(expireAfterSeconds: 3600)
      end
    end

    context "when providing an invalid option" do

      it "raises an error" do
        expect {
          klass.index({ name: 1 }, { invalid: true })
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
            klass.index({ name: "something" })
          }.to raise_error(Mongoid::Errors::InvalidIndex)
        end
      end
    end
  end
end
