require "spec_helper"

describe Mongoid::Indexable do

  describe ".included" do

    let(:klass) do
      Class.new do
        include Mongoid::Indexable
      end
    end

    it "adds an index_specifications accessor" do
      expect(klass).to respond_to(:index_specifications)
    end

    it "defaults index_specifications to empty array" do
      expect(klass.index_specifications).to be_empty
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
        expect(collection.indexes.reject{ |doc| doc["name"] == "_id_" }).to be_empty
      end
    end

    context "when database specific options exist", if: non_legacy_server? do

      let(:klass) do
        Class.new do
          include Mongoid::Document
          store_in collection: "test_db_remove"
          index({ test: 1 }, { database: "mongoid_optional" })
          index({ name: 1 }, { background: true })
        end
      end

      before do
        klass.create_indexes
        klass.remove_indexes
      end

      let(:indexes) do
        klass.with(database: "mongoid_optional").collection.indexes
      end

      it "creates the indexes" do
        expect(indexes.reject{ |doc| doc["name"] == "_id_" }).to be_empty
      end
    end
  end

  describe ".create_indexes" do

    context "when no database options are specified" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
          store_in collection: "test_class"
          index({ _type: 1 }, unique: false, background: true)
        end
      end

      before do
        klass.create_indexes
      end

      it "creates the indexes" do
        expect(klass.collection.indexes.get(_type: 1)).to_not be_nil
      end
    end

    context "when database options are specified", if: non_legacy_server? do

      let(:klass) do
        Class.new do
          include Mongoid::Document
          store_in collection: "test_db_indexes"
          index({ _type: 1 }, { database: "mongoid_optional" })
        end
      end

      before do
        klass.create_indexes
      end

      after do
        klass.remove_indexes
      end

      let(:indexes) do
        klass.with(database: "mongoid_optional").collection.indexes
      end

      it "creates the indexes" do
        expect(indexes.get(_type: 1)).to_not be_nil
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

      let(:spec) do
        klass.index_specification(_type: 1)
      end

      it "adds the _type index" do
        expect(spec.options).to eq(unique: false, background: true)
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
        klass.index({ authentication_token: 1 }, unique: true)
      end

      let(:options) do
        klass.index_specification(a: 1).options
      end

      it "sets the index with unique options" do
        expect(options).to eq(unique: true)
      end
    end

    context "when providing unique options" do

      before do
        klass.index({ name: 1 }, unique: true)
      end

      let(:options) do
        klass.index_specification(name: 1).options
      end

      it "sets the index with unique options" do
        expect(options).to eq(unique: true)
      end
    end

    context "when providing a drop_dups option" do

      before do
        klass.index({ name: 1 }, drop_dups: true)
      end

      let(:options) do
        klass.index_specification(name: 1).options
      end

      it "sets the index with drop_dups option" do
        expect(options).to eq(drop_dups: true)
      end
    end

    context "when providing a sparse option" do

      before do
        klass.index({ name: 1 }, sparse: true)
      end

      let(:options) do
        klass.index_specification(name: 1).options
      end

      it "sets the index with sparse options" do
        expect(options).to eq(sparse: true)
      end
    end

    context "when providing a name option" do

      before do
        klass.index({ name: 1 }, name: "index_name")
      end

      let(:options) do
        klass.index_specification(name: 1).options
      end

      it "sets the index with name options" do
        expect(options).to eq(name: "index_name")
      end
    end

    context "when providing database options" do

      before do
        klass.index({ name: 1 }, database: "mongoid_index_alt")
      end

      let(:options) do
        klass.index_specification(name: 1).options
      end

      it "sets the index with background options" do
        expect(options).to eq(database: "mongoid_index_alt")
      end
    end

    context "when providing a background option" do

      before do
        klass.index({ name: 1 }, background: true)
      end

      let(:options) do
        klass.index_specification(name: 1).options
      end

      it "sets the index with background options" do
        expect(options).to eq(background: true)
      end
    end

    context "when providing a compound index" do

      before do
        klass.index({ name: 1, title: -1 })
      end

      let(:options) do
        klass.index_specification(name: 1, title: -1).options
      end

      it "sets the compound key index" do
        expect(options).to be_empty
      end
    end

    context "when providing multiple inverse compound indexes" do

      before do
        klass.index({ name: 1, title: -1 })
        klass.index({ title: -1, name: 1 })
      end

      let(:first_spec) do
        klass.index_specification(name: 1, title: -1)
      end

      let(:second_spec) do
        klass.index_specification(title: -1, name: 1)
      end

      it "does not overwrite the index options" do
        expect(first_spec).to_not eq(second_spec)
      end
    end

    context "when providing multiple compound indexes with different order" do

      before do
        klass.index({ name: 1, title: -1 })
        klass.index({ name: 1, title: 1 })
      end

      let(:first_spec) do
        klass.index_specification(name: 1, title: -1)
      end

      let(:second_spec) do
        klass.index_specification(name: 1, title: 1)
      end

      it "does not overwrite the index options" do
        expect(first_spec).to_not eq(second_spec)
      end
    end

    context "when providing a geospacial index" do

      before do
        klass.index({ location: "2d" }, { min: -200, max: 200, bits: 32 })
      end

      let(:options) do
        klass.index_specification(location: "2d").options
      end

      it "sets the geospacial index" do
        expect(options).to eq({ min: -200, max: 200, bits: 32 })
      end
    end

    context "when providing a geo haystack index with a bucket_size" do

      before do
        klass.index({ location: "geoHaystack" }, { min: -200, max: 200, bucket_size: 0.5 })
      end

      let(:options) do
        klass.index_specification(location: "geoHaystack").options
      end

      it "sets the geo haystack index with the bucket_size option" do
        expect(options).to eq({ min: -200, max: 200, bucket_size: 0.5 })
      end
    end

    context "when providing a Spherical Geospatial index" do

      before do
        klass.index({ location: "2dsphere" })
      end

      let(:options) do
        klass.index_specification(location: "2dsphere").options
      end

      it "sets the spherical geospatial index" do
        expect(options).to be_empty
      end
    end

    context "when providing a text index" do

      context "when the index is a single field" do

        before do
          klass.index({ description: "text" })
        end

        let(:options) do
          klass.index_specification(description: "text").options
        end

        it "allows the set of the text index" do
          expect(options).to be_empty
        end
      end

      context "when the index is multiple fields" do

        before do
          klass.index({ description: "text", name: "text" })
        end

        let(:options) do
          klass.index_specification(description: "text", name: "text").options
        end

        it "allows the set of the text index" do
          expect(options).to be_empty
        end
      end

      context "when the index is all string fields" do

        before do
          klass.index({ "$**" => "text" })
        end

        let(:options) do
          klass.index_specification(:"$**" => "text").options
        end

        it "allows the set of the text index" do
          expect(options).to be_empty
        end
      end

      context "when providing a default language" do

        before do
          klass.index({ description: "text" }, default_language: "english")
        end

        let(:options) do
          klass.index_specification(description: "text").options
        end

        it "allows the set of the text index" do
          expect(options).to eq(default_language: "english")
        end
      end

      context "when providing a name" do

        before do
          klass.index({ description: "text" }, name: "text_index")
        end

        let(:options) do
          klass.index_specification(description: "text").options
        end

        it "allows the set of the text index" do
          expect(options).to eq(name: "text_index")
        end
      end
    end

    context "when providing a hashed index" do

      before do
        klass.index({ a: "hashed" })
      end

      let(:options) do
        klass.index_specification(a: "hashed").options
      end

      it "sets the hashed index" do
        expect(options).to be_empty
      end
    end

    context "when providing a text index" do

      before do
        klass.index({ content: "text" })
      end

      let(:options) do
        klass.index_specification(content: "text").options
      end

      it "sets the text index" do
        expect(options).to be_empty
      end
    end

    context "when providing a compound text index" do

      before do
        klass.index({ content: "text", title: "text" }, { weights: { content: 1, title: 2 } })
      end

      let(:options) do
        klass.index_specification(content: "text", title: "text").options
      end

      it "sets the compound text index" do
        expect(options).to eq(weights: { content: 1, title: 2 })
      end
    end

    context "when providing an expire_after_seconds option" do

      before do
        klass.index({ name: 1 }, { expire_after_seconds: 3600 })
      end

      let(:options) do
        klass.index_specification(name: 1).options
      end

      it "sets the index with expire_after option" do
        expect(options).to eq(expire_after: 3600)
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
