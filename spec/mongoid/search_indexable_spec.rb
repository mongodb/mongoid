# frozen_string_literal: true

require 'spec_helper'

class SearchIndexHelper
  attr_reader :model

  def initialize(model)
    @model = model
    model.collection.drop
    model.collection.create
  end

  def collection
    model.collection
  end

  # Wait for all of the indexes with the given names to be ready; then return
  # the list of index definitions corresponding to those names.
  def wait_for(*names, &condition)
    names.flatten!

    timeboxed_wait do
      result = collection.search_indexes
      return filter_results(result, names) if names.all? { |name| ready?(result, name, &condition) }
    end
  end

  # Wait until all of the indexes with the given names are absent from the
  # search index list.
  def wait_for_absence_of(*names)
    names.flatten.each do |name|
      timeboxed_wait do
        break if collection.search_indexes(name: name).empty?
      end
    end
  end

  private

  def timeboxed_wait(step: 5, max: 300)
    start = Mongo::Utils.monotonic_time

    loop do
      yield

      sleep step
      raise Timeout::Error, 'wait took too long' if Mongo::Utils.monotonic_time - start > max
    end
  end

  # Returns true if the list of search indexes includes one with the given name,
  # which is ready to be queried.
  def ready?(list, name, &condition)
    condition ||= ->(index) { index['queryable'] }
    list.any? { |index| index['name'] == name && condition[index] }
  end

  def filter_results(result, names)
    result.select { |index| names.include?(index['name']) }
  end
end

describe Mongoid::SearchIndexable do
  # Unit tests — no Atlas connection required.

  describe '.search_index_specs' do
    let(:model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        search_index mappings: { dynamic: false }
        search_index :with_dynamic_mappings, mappings: { dynamic: true }
      end
    end

    let(:vector_model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        vector_search_index fields: [ { type: 'vector', path: 'embedding', numDimensions: 1536, similarity: 'cosine' } ]
        vector_search_index :named_vector_index, fields: [ { type: 'vector', path: 'other', numDimensions: 768, similarity: 'euclidean' } ]
      end
    end

    context 'when no search indexes have been defined' do
      it 'has no search index specs' do
        expect(Person.search_index_specs).to be_empty
      end
    end

    context 'when search indexes have been defined' do
      it 'has search index specs' do
        expect(model.search_index_specs).to eq [
          { definition: { mappings: { dynamic: false } } },
          { name: 'with_dynamic_mappings', definition: { mappings: { dynamic: true } } }
        ]
      end
    end

    context 'when vector search indexes have been defined' do
      it 'has search index specs with vectorSearch type' do
        expect(vector_model.search_index_specs).to eq [
          { type: 'vectorSearch', definition: { fields: [ { type: 'vector', path: 'embedding', numDimensions: 1536, similarity: 'cosine' } ] } },
          { type: 'vectorSearch', name: 'named_vector_index', definition: { fields: [ { type: 'vector', path: 'other', numDimensions: 768, similarity: 'euclidean' } ] } }
        ]
      end
    end
  end

  describe '.vector_search_index' do
    let(:vector_model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        field :embedding, type: Array
        vector_search_index fields: [ { type: 'vector', path: 'embedding', numDimensions: 3, similarity: 'cosine' } ]
      end
    end

    it 'adds a vector_search_score field to the model' do
      expect(vector_model.fields).to have_key('vector_search_score')
    end

    it 'marks vector_search_score as readonly' do
      expect(vector_model.readonly_attributes).to include('vector_search_score')
    end

    it 'defines vector_search_score only once across multiple declarations' do
      model = Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        vector_search_index :idx1, fields: [ { type: 'vector', path: 'a', numDimensions: 3, similarity: 'cosine' } ]
        vector_search_index :idx2, fields: [ { type: 'vector', path: 'b', numDimensions: 3, similarity: 'cosine' } ]
      end
      expect(model.fields.count { |k, _| k == 'vector_search_score' }).to eq 1
    end

    context 'when only a regular search_index is declared' do
      it 'does not add vector_search_score' do
        model = Class.new do
          include Mongoid::Document

          store_in collection: BSON::ObjectId.new.to_s
          search_index mappings: { dynamic: true }
        end
        expect(model.fields).not_to have_key('vector_search_score')
      end
    end
  end

  describe '.vector_search argument validation' do
    let(:no_index_model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
      end
    end

    let(:multi_index_model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        vector_search_index :idx1, fields: [ { type: 'vector', path: 'a', numDimensions: 3, similarity: 'cosine' } ]
        vector_search_index :idx2, fields: [ { type: 'vector', path: 'b', numDimensions: 3, similarity: 'cosine' } ]
      end
    end

    let(:single_index_model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        field :embedding, type: Array
        vector_search_index fields: [ { type: 'vector', path: 'embedding', numDimensions: 3, similarity: 'cosine' } ]
      end
    end

    it 'raises ArgumentError when no vector search indexes are declared' do
      expect { no_index_model.vector_search([ 0.1, 0.2, 0.3 ]) }
        .to raise_error(ArgumentError, /No vector search indexes declared/)
    end

    it 'raises ArgumentError when multiple indexes exist and none is specified' do
      expect { multi_index_model.vector_search([ 0.1, 0.2, 0.3 ]) }
        .to raise_error(ArgumentError, /multiple vector search indexes/)
    end

    it 'raises ArgumentError when the specified index name does not exist' do
      expect { single_index_model.vector_search([ 0.1, 0.2, 0.3 ], index: 'nonexistent') }
        .to raise_error(ArgumentError, /No vector search index 'nonexistent'/)
    end
  end

  describe '#vector_search argument validation' do
    let(:model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        field :embedding, type: Array
        vector_search_index fields: [ { type: 'vector', path: 'embedding', numDimensions: 3, similarity: 'cosine' } ]
      end
    end

    it 'raises ArgumentError when the vector field is nil' do
      doc = model.new(embedding: nil)
      expect { doc.vector_search }.to raise_error(ArgumentError, /embedding is nil/)
    end
  end

  describe '.auto_embed_search argument validation' do
    let(:no_index_model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
      end
    end

    let(:single_embed_model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        auto_embed_field :description, model: 'voyage-4'
      end
    end

    let(:multi_embed_model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        auto_embed_field :description, model: 'voyage-4', index: :idx1
        auto_embed_field :summary,     model: 'voyage-4', index: :idx2
      end
    end

    it 'raises ArgumentError when no auto-embed indexes are declared' do
      expect { no_index_model.auto_embed_search('hello') }
        .to raise_error(ArgumentError, /No auto-embed indexes declared/)
    end

    it 'raises ArgumentError when multiple indexes exist and none is specified' do
      expect { multi_embed_model.auto_embed_search('hello') }
        .to raise_error(ArgumentError, /multiple auto-embed indexes/)
    end

    it 'raises ArgumentError when the specified index name does not exist' do
      expect { single_embed_model.auto_embed_search('hello', index: 'nonexistent') }
        .to raise_error(ArgumentError, /No auto-embed index 'nonexistent'/)
    end

    it 'raises ArgumentError when a model with only vector (non-autoEmbed) indexes is used' do
      model = Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        vector_search_index fields: [ { type: 'vector', path: 'emb', numDimensions: 3, similarity: 'cosine' } ]
      end
      expect { model.auto_embed_search('hello') }
        .to raise_error(ArgumentError, /No auto-embed indexes declared/)
    end
  end

  # Atlas integration tests — skipped when ATLAS_URI is not set.

  context 'Atlas integration' do
    before do
      skip "#{described_class} requires an Atlas environment (set ATLAS_URI)" if ENV['ATLAS_URI'].nil?
    end

    let(:model) do
      Class.new do
        include Mongoid::Document

        store_in collection: BSON::ObjectId.new.to_s
        search_index mappings: { dynamic: false }
        search_index :with_dynamic_mappings, mappings: { dynamic: true }
      end
    end

    let(:helper) { SearchIndexHelper.new(model) }

    context 'when needing to first create search indexes' do
      let(:requested_definitions) { model.search_index_specs.map { |spec| spec[:definition].with_indifferent_access } }
      let(:index_names) { model.create_search_indexes }
      let(:actual_indexes) { helper.wait_for(*index_names) }
      let(:actual_definitions) { actual_indexes.map { |i| i['latestDefinition'] } }

      describe '.create_search_indexes' do
        it 'creates the indexes' do
          expect(actual_definitions).to eq requested_definitions
        end
      end

      describe '.search_indexes' do
        before { actual_indexes } # wait for the indices to be created

        let(:queried_definitions) { model.search_indexes.map { |i| i['latestDefinition'] } }

        it 'queries the available search indexes' do
          expect(queried_definitions).to eq requested_definitions
        end
      end

      describe '.remove_search_index' do
        let(:target_index) { actual_indexes.first }

        before do
          model.remove_search_index id: target_index['id']
          helper.wait_for_absence_of target_index['name']
        end

        it 'removes the requested index' do
          expect(model.search_indexes(id: target_index['id'])).to be_empty
        end
      end

      describe '.remove_search_indexes' do
        before do
          actual_indexes # wait for the indexes to be created
          model.remove_search_indexes
          helper.wait_for_absence_of(actual_indexes.map { |i| i['name'] })
        end

        it 'removes the indexes' do
          expect(model.search_indexes).to be_empty
        end
      end
    end

    context 'with a vector search index' do
      let(:vector_model) do
        Class.new do
          include Mongoid::Document

          store_in collection: BSON::ObjectId.new.to_s
          field :embedding, type: Array
          vector_search_index fields: [ { type: 'vector', path: 'embedding', numDimensions: 3, similarity: 'cosine' } ]
        end
      end

      let(:vector_helper) { SearchIndexHelper.new(vector_model) }

      # Three orthogonal unit vectors as a minimal, predictable dataset.
      let!(:doc_a) { vector_model.create!(embedding: [ 1.0, 0.0, 0.0 ]) }
      let!(:doc_b) { vector_model.create!(embedding: [ 0.0, 1.0, 0.0 ]) }
      let!(:doc_c) { vector_model.create!(embedding: [ 0.0, 0.0, 1.0 ]) }

      before do
        names = vector_model.create_search_indexes
        vector_helper.wait_for(*names)
      end

      describe '.vector_search' do
        let(:results) { vector_model.vector_search([ 1.0, 0.0, 0.0 ], limit: 3) }

        it 'returns Mongoid document instances' do
          expect(results).to all(be_a(vector_model))
        end

        it 'populates vector_search_score on each result' do
          expect(results.map(&:vector_search_score)).to all(be_a(Float))
        end

        it 'excludes the vector field from results' do
          expect(results.map(&:embedding)).to all(be_nil)
        end

        it 'orders results by descending score' do
          scores = results.map(&:vector_search_score)
          expect(scores).to eq(scores.sort.reverse)
        end
      end

      describe '#vector_search' do
        let(:results) { doc_a.vector_search(limit: 3) }

        it 'returns Mongoid document instances' do
          expect(results).to all(be_a(vector_model))
        end

        it 'populates vector_search_score on each result' do
          expect(results.map(&:vector_search_score)).to all(be_a(Float))
        end

        it 'excludes the source document from results' do
          expect(results.map(&:id)).not_to include(doc_a.id)
        end
      end
    end
  end
end
