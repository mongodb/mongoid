# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Indexable do

  after do
    Person.collection.drop
  end

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

    context "when database specific options exist" do

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
        klass.with(database: "mongoid_optional") do |klass|
          klass.collection.indexes
        end
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

      it "creates the indexes by using specified background option" do
        index = klass.collection.indexes.get(_type: 1)
        expect(index[:background]).to eq(true)
      end
    end

    context "when database options are specified" do

      let(:klass) do
        Class.new do
          include Mongoid::Document
          store_in collection: "test_db_indexes"
          index({ _type: 1 }, { database: "mongoid_optional" })
        end
      end

      after do
        klass.remove_indexes
      end

      let(:indexes) do
        klass.with(database: "mongoid_optional") do |klass|
          klass.collection.indexes
        end
      end

      context "when the background_indexing option is false" do
        config_override :background_indexing, false

        it "creates the indexes correctly" do
          klass.create_indexes

          index = indexes.get(_type: 1)
          expect(index[:background]).to be false
        end
      end

      context "when the background_indexing option is true" do
        config_override :background_indexing, true

        it "creates the indexes correctly" do

          klass.create_indexes

          index = indexes.get(_type: 1)
          expect(index[:background]).to be true
        end
      end
    end

    context "when a collation option is specified" do
      min_server_version '3.4'

      let(:klass) do
        Class.new do
          include Mongoid::Document
          store_in collection: "test_db_indexes"
          index({ name: 1 }, { collation: { locale: 'en_US', strength: 2 }})
        end
      end

      before do
        klass.create_indexes
      end

      after do
        klass.remove_indexes
      end

      let(:indexes) do
        klass.collection.indexes
      end

      it "creates the indexes" do
        expect(indexes.get("name_1")["collation"]).to_not be_nil
        expect(indexes.get("name_1")["collation"]["locale"]).to eq('en_US')
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

    context "when using a custom discriminator_key" do
      context "when indexes have not been added" do
        let(:klass) do
          Class.new do
            include Mongoid::Document
            self.discriminator_key = "dkey"
            def self.hereditary?
              true
            end
          end
        end

        before do
          klass.add_indexes
        end

        let(:spec) do
          klass.index_specification(dkey: 1)
        end

        it "adds the _type index" do
          expect(spec.options).to eq(unique: false, background: true)
        end
      end
    end
  end

  describe ".index" do

    let(:klass) do
      Class.new do
        include Mongoid::Document

        store_in collection: :specs

        field :a, as: :authentication_token
        field :username

        alias_attribute :u, :username

        embeds_many :addresses, store_as: :adrs
      end
    end

    after do
      klass.collection.drop
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

    context "when indexing a field that is embedded" do

      before do
        klass.index({ 'addresses.house' => 1 }, unique: true)
      end

      let(:options) do
        klass.index_specification('adrs.h': 1).options
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

    context "when providing a collation option" do
      min_server_version '3.4'

      before do
        klass.index({ name: 1 }, collation: { locale: 'en_US', strength: 2 })
      end

      let(:options) do
        klass.index_specification(name: 1).options
      end

      it "sets the index with a collation option" do
        expect(options).to eq(collation: { locale: 'en_US', strength: 2 })
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

    context "when providing a geospatial index" do

      before do
        klass.index({ location: "2d" }, { min: -200, max: 200, bits: 32 })
      end

      let(:options) do
        klass.index_specification(location: "2d").options
      end

      it "sets the geospatial index" do
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

    context "when providing a geo haystack index with a bucket_size" do

      let(:message) do
        'The geoHaystack type is deprecated.'
      end

      it "logs a deprecation warning" do
        expect(Mongoid::Warnings).to receive(:warn_geo_haystack_deprecated)
        klass.index({ location: "geoHaystack" }, { min: -200, max: 200, bucket_size: 0.5 })
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

    context "when using partial_filter_expression option" do

      context 'when not using an alias' do

        before do
          klass.index({ authentication_token: 1 }, partial_filter_expression: { username: { '$exists' => true } })
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        it "sets the index with correct options" do
          expect(options).to eq(partial_filter_expression: { username: { '$exists' => true } })
        end
      end

      context 'when using an alias via field :as option' do

        before do
          klass.index({ authentication_token: 1 }, partial_filter_expression: { authentication_token: { '$exists' => true } })
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        it "sets the index with correct options" do
          expect(options).to eq(partial_filter_expression: { a: { '$exists' => true } })
        end
      end

      context 'when using an alias via alias_attribute' do

        before do
          klass.index({ u: 1 }, partial_filter_expression: { u: { '$exists' => true } })
        end

        let(:options) do
          klass.index_specification(username: 1).options
        end

        it "sets the index with correct options" do
          expect(options).to eq(partial_filter_expression: { username: { '$exists' => true } })
        end
      end

      context 'when using an embedded field' do

        before do
          klass.index({ authentication_token: 1 }, partial_filter_expression: { 'addresses.house' => { '$exists' => true } })
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        it "sets the index with correct options" do
          expect(options).to eq(partial_filter_expression: { 'adrs.h': { '$exists' => true } })
        end
      end

      context 'when using nested $and operator' do
        let(:partial_filter_expression) do
          {
            '$and' => [
              { 'authentication_token' => { '$gte' => 0 } },
              { 'authentication_token' => { '$type' => 16 } }
            ]
          }
        end

        before do
          klass.index({ authentication_token: 1 }, partial_filter_expression: partial_filter_expression)
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        let(:expected) do
          {
            '$and': [
              { 'a': { '$gte' => 0 } },
              { 'a': { '$type' => 16 } }
            ]
          }
        end

        it "resolves alias on $and option" do
          expect(options[:partial_filter_expression]).to eq(expected)
        end
      end

      context 'when using nested operators other than $and' do
        let(:partial_filter_expression) do
          {
            'username' => { '$eq' => 'authentication_token' },
            'addresses.house' => { '$exists' => true }
          }
        end

        before do
          klass.index({ authentication_token: 1 }, partial_filter_expression: partial_filter_expression)
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        let(:expected) do
          {
            username: { '$eq' => 'authentication_token' },
            'adrs.h': { '$exists' => true }
          }
        end

        it "preserves other operators" do
          expect(options[:partial_filter_expression]).to eq(expected)
        end
      end

      context 'when using mixed nested operators' do
        let(:partial_filter_expression) do
          {
            'username' => { '$eq' => 'authentication_token' },
            'addresses.house' => { '$exists' => true },
            '$and' => [
              { 'authentication_token' => { '$gte' => 0 } },
              { 'authentication_token' => { '$type' => 16 } }
            ]
          }
        end

        before do
          klass.index({ authentication_token: 1 }, partial_filter_expression: partial_filter_expression)
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        let(:expected) do
          {
            username: { '$eq' => 'authentication_token' },
            'adrs.h': { '$exists' => true },
            '$and': [
              { 'a': { '$gte' => 0 } },
              { 'a': { '$type' => 16 } }
            ]
          }
        end

        it "resolves aliases on $ operators" do
          expect(options[:partial_filter_expression]).to eq(expected)
        end
      end

      context 'when using multiple levels of nonsensical nested operators' do
        let(:partial_filter_expression) do
          {
            '$foo' => {
              '$eq' => [{
                '$bar' => {
                  '$and' => [
                    { 'authentication_token' => { '$gte' => { 'aliased_timestamp' => 16 } } },
                    { 'authentication_token' => { 'aliased_timestamp' => 16 } },
                    { 'addresses.house' => { 'authentication_token' => [{ 'aliased_timestamp' => 16 }] } }
                  ]
                }
              }]
            }
          }
        end

        before do
          klass.index({ authentication_token: 1 }, partial_filter_expression: partial_filter_expression)
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        let(:expected) do
          {
            '$foo': {
              '$eq': [{
                '$bar': {
                  '$and': [
                    { a: { '$gte' => { 'aliased_timestamp' => 16 } } },
                    { a: { 'aliased_timestamp' => 16 } },
                    { 'adrs.h': { 'authentication_token' => [{ 'aliased_timestamp' => 16 }] } }
                  ]
                }
              }]
            }
          }
        end

        it "resolves aliases recursively only on $ operators" do
          expect(options[:partial_filter_expression]).to eq(expected)
        end
      end
    end

    context "when using weights option" do

      context 'when not using aliases' do

        before do
          klass.index({ authentication_token: 1 }, weights: { a: 1, username: 2 })
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        it "sets the index with correct options" do
          expect(options).to eq(weights: { a: 1, username: 2 })
        end
      end

      context 'when using aliases via field :as option' do

        before do
          klass.index({ authentication_token: 1 }, weights: { 'addresses.house' => 1, authentication_token: 2 })
        end

        let(:options) do
          klass.index_specification(a: 1).options
        end

        it "sets the index with correct options" do
          expect(options).to eq(weights: { 'adrs.h': 1, a: 2 })
        end
      end

      context 'when using aliases via alias_attribute' do

        before do
          klass.index({ u: 1 }, weights: { 'addresses.n' => 1, u: 2 })
        end

        let(:options) do
          klass.index_specification(username: 1).options
        end

        it "sets the index with correct options" do
          expect(options).to eq(weights: { 'adrs.name': 1, username: 2 })
        end
      end
    end

    context "when using wildcard indexes" do

      context 'when not using an alias' do

        before do
          klass.index({ '$**': 1 }, wildcard_projection: { _id: 1, username: 0 })
        end

        let(:spec) do
          klass.index_specification('$**': 1)
        end

        it "creates the index" do
          expect(spec).to be_a(Mongoid::Indexable::Specification)
        end

        it "sets the index with correct options" do
          expect(spec.options).to eq(wildcard_projection: { _id: 1, username: 0 })
        end
      end

      context 'when using an alias via field :as option' do

        before do
          klass.index({ 'addresses.$**': 1 }, wildcard_projection: { 'addresses.house' => 1 })
        end

        let(:spec) do
          klass.index_specification('adrs.$**': 1)
        end

        it "creates the index" do
          expect(spec).to be_a(Mongoid::Indexable::Specification)
        end

        it "sets the index with correct options" do
          expect(spec.options).to eq(wildcard_projection: { 'adrs.h': 1 })
        end
      end

      context 'when using aliases via alias_attribute' do

        before do
          klass.index({ 'addresses.$**': 1 }, wildcard_projection: { 'addresses.n' => 1 })
        end

        let(:spec) do
          klass.index_specification('adrs.$**': 1)
        end

        it "creates the index" do
          expect(spec).to be_a(Mongoid::Indexable::Specification)
        end

        it "sets the index with correct options" do
          expect(spec.options).to eq(wildcard_projection: { 'adrs.name': 1 })
        end
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

    context 'when declaring a duplicate index with different options' do
      def declare_duplicate_indexes!
        klass.index({ name: 1 }, { partial_filter_expression: { name: 'a' } })
        klass.index({ name: 1 }, { partial_filter_expression: { name: 'b' } })
        klass.create_indexes
      end

      context 'when allow_duplicate_index_declarations is false' do
        config_override :allow_duplicate_index_declarations, false

        it 'silently ignores the duplicate definition' do
          expect { declare_duplicate_indexes! }.not_to raise_exception
        end
      end

      context 'when allow_duplicate_index_declarations is true' do
        config_override :allow_duplicate_index_declarations, true

        it 'raises a server error' do
          expect { declare_duplicate_indexes! }.to raise_exception
        end
      end
    end

    context 'when declaring a duplicate index with different names' do
      def declare_duplicate_indexes!
        klass.index({ name: 1 }, { partial_filter_expression: { name: 'a' } })
        klass.index({ name: 1 }, { name: 'alt_name', partial_filter_expression: { name: 'b' } })
        klass.create_indexes
      end

      let(:index_count) { klass.collection.indexes.count }


      context 'when allow_duplicate_index_declarations is false' do
        config_override :allow_duplicate_index_declarations, false

        it 'silently ignores the duplicate definition' do
          expect { declare_duplicate_indexes! }.not_to raise_exception
          expect(index_count).to be == 2 # _id and name
        end
      end

      context 'when allow_duplicate_index_declarations is true' do
        # 4.4 apparently doesn't recognize :name option for indexes?
        min_server_version '5.0'

        config_override :allow_duplicate_index_declarations, true

        it 'creates both indexes' do
          expect { declare_duplicate_indexes! }.not_to raise_exception
          expect(index_count).to be == 3 # _id, name, alt_name
        end
      end
    end
  end
end
