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

  describe 'Hash field' do
    context 'with symbol key and value' do
      let(:church) do
        Church.create!(location: {state: :ny})
      end

      let(:found_church) do
        Church.find(church.id)
      end

      it 'round-trips the value' do
        found_church.location[:state].should == :ny
      end

      it 'stringifies the key' do
        found_church.location.keys.should == %w(state)
      end

      it 'retrieves value as symbol via driver' do
        Church.delete_all

        church

        v = Church.collection.find.first
        v['location'].should == {'state' => :ny}
      end
    end
  end

  context 'Regexp field' do
    shared_examples "persists strings as regexp" do |type|
      it 'persists strings as regexp' do
        mop = Mop.create!(regexp_field: 'foo')
        expect(mop.regexp_field).to be_a Regexp
        expect(Mop.find(mop.id).regexp_field).to be_a BSON::Regexp::Raw
        expect(
          Mop.collection.find(
            "_id" => mop.id,
            "regexp_field" => { "$type" => type }
          ).count
        ).to be == 1
      end
    end

    context "< 3.2" do
      max_server_version("3.1")
      include_examples "persists strings as regexp", 11
    end

    context ">= 3.2" do
      min_server_version("3.2")
      it_behaves_like "persists strings as regexp", "regex"
    end
  end
end
