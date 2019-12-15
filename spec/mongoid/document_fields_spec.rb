# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Document do

  describe 'BSON::Binary field' do
    context 'when assigned a BSON::Binary instance' do
      let(:data) do
        BSON::Binary.new("hello world")
      end

      let(:registry) do
        Registry.new(data: data)
      end

      it 'does not freeze the specified data' do
        registry

        data.should_not be_frozen
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.data.should == data
      end
    end

    context 'when assigned a binary string' do
      let(:data) do
        # Frozen string literals do not allow setting encoding on a string
        # literal - work around by composing the string at runtime
        ([0, 253, 254] * 2).map(&:chr).join.force_encoding('BINARY')
      end

      let(:registry) do
        Registry.new(data: data)
      end

      it 'assigns as a BSON::Binary object' do
        pending 'https://jira.mongodb.org/browse/MONGOID-4823'

        registry.data.should be_a(BSON::Binary)
      end

      it 'persists' do
        pending 'https://jira.mongodb.org/browse/MONGOID-4823'

        registry.save!

        _registry = Registry.find(registry.id)
        _registry.data.should == BSON::Binary.new(data)
      end
    end
  end
end
