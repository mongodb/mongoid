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
  def wait_for_absense_of(*names)
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

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe Mongoid::SearchIndexable do
  before do
    skip "#{described_class} requires at Atlas environment (set ATLAS_URI)" if ENV['ATLAS_URI'].nil?
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

  describe '.search_index_specs' do
    context 'when no search indexes have been defined' do
      it 'has no search index specs' do
        expect(Person.search_index_specs).to be_empty
      end
    end

    context 'when search indexes have been defined' do
      it 'has search index specs' do
        expect(model.search_index_specs).to be == [
          { definition: { mappings: { dynamic: false } } },
          { name: 'with_dynamic_mappings', definition: { mappings: { dynamic: true } } }
        ]
      end
    end
  end

  context 'when needing to first create search indexes' do
    let(:requested_definitions) { model.search_index_specs.map { |spec| spec[:definition].with_indifferent_access } }
    let(:index_names) { model.create_search_indexes }
    let(:actual_indexes) { helper.wait_for(*index_names) }
    let(:actual_definitions) { actual_indexes.map { |i| i['latestDefinition'] } }

    describe '.create_search_indexes' do
      it 'creates the indexes' do
        expect(actual_definitions).to be == requested_definitions
      end
    end

    describe '.search_indexes' do
      before { actual_indexes } # wait for the indices to be created

      let(:queried_definitions) { model.search_indexes.map { |i| i['latestDefinition'] } }

      it 'queries the available search indexes' do
        expect(queried_definitions).to be == requested_definitions
      end
    end

    describe '.remove_search_index' do
      let(:target_index) { actual_indexes.first }

      before do
        model.remove_search_index id: target_index['id']
        helper.wait_for_absense_of target_index['name']
      end

      it 'removes the requested index' do
        expect(model.search_indexes(id: target_index['id'])).to be_empty
      end
    end

    describe '.remove_search_indexes' do
      before do
        actual_indexes # wait for the indexes to be created
        model.remove_search_indexes
        helper.wait_for_absense_of(actual_indexes.map { |i| i['name'] })
      end

      it 'removes the indexes' do
        expect(model.search_indexes).to be_empty
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
