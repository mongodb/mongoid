# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/LeakyConstantDeclaration
# rubocop:disable Lint/ConstantDefinitionInBlock
describe 'Collection options' do
  before(:all) do
    class CollectionOptionsCapped
      include Mongoid::Document

      store_in collection_options: {
        capped: true,
        size: 25_600
      }
    end
  end

  after(:all) do
    CollectionOptionsCapped.collection.drop
    Mongoid.deregister_model(CollectionOptionsCapped)
    Object.send(:remove_const, :CollectionOptionsCapped)
  end

  before do
    CollectionOptionsCapped.collection.drop
    # We should create the collection explicitly to apply collection options.
    CollectionOptionsCapped.create_collection
  end

  it 'creates a document' do
    expect { CollectionOptionsCapped.create! }.not_to raise_error
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock
# rubocop:enable RSpec/LeakyConstantDeclaration
