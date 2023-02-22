# frozen_string_literal: true

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

        expect(data).not_to be_frozen
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.data).to eq(data)
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
        expect(registry.data).to be_a(BSON::Binary)
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.data).to eq(BSON::Binary.new(data))
      end
    end

    context 'when assigned nil' do
      let(:data) do
        nil
      end

      let(:registry) do
        Registry.new(data: data)
      end

      it 'assigns nil' do
        expect(registry.data).to be nil
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.data).to be nil
      end
    end

    context 'when assigned an invalid type' do
      let(:data) do
        true
      end

      let(:registry) do
        Registry.new(data: data)
      end

      it 'assigns nil' do
        expect(registry.data).to be nil
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.data).to be nil
      end
    end
  end

  describe 'BSON::ObjectId field' do
    context 'when assigned a BSON::ObjectId instance' do
      let(:obj_id) do
        BSON::ObjectId.new
      end

      let(:registry) do
        Registry.new(obj_id: obj_id)
      end

      it 'does not freeze the specified data' do
        registry

        expect(obj_id).not_to be_frozen
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.obj_id).to eq(obj_id)
      end
    end

    context 'when assigned a valid string' do
      let(:obj_id) do
        BSON::ObjectId.new.to_s
      end

      let(:registry) do
        Registry.new(obj_id: obj_id)
      end

      it 'assigns as a BSON::Binary object' do
        expect(registry.obj_id).to be_a(BSON::ObjectId)
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.obj_id).to eq(BSON::ObjectId.from_string(obj_id))
      end
    end

    context 'when assigned nil' do
      let(:obj_id) do
        nil
      end

      let(:registry) do
        Registry.new(obj_id: obj_id)
      end

      it 'assigns nil' do
        expect(registry.obj_id).to be nil
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.obj_id).to be nil
      end
    end

    context 'when assigned an invalid string' do
      let(:obj_id) do
        "hello"
      end

      let(:registry) do
        Registry.new(obj_id: obj_id)
      end

      it 'assigns nil' do
        expect(registry.obj_id).to eq("hello")
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.obj_id).to eq("hello")
      end
    end

    context 'when assigned an invalid type' do
      let(:obj_id) do
        :sym
      end

      let(:registry) do
        Registry.new(obj_id: obj_id)
      end

      it 'assigns nil' do
        expect(registry.obj_id).to eq(:sym)
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        expect(_registry.obj_id).to eq(:sym)
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
        expect(found_church.location[:state]).to eq(:ny)
      end

      it 'stringifies the key' do
        expect(found_church.location.keys).to eq(%w(state))
      end

      it 'retrieves value as symbol via driver' do
        Church.delete_all

        church

        v = Church.collection.find.first
        expect(v['location']).to eq({'state' => :ny})
      end
    end
  end

  context 'Regexp field' do
    it 'persists strings as regexp' do
      mop = Mop.create!(regexp_field: 'foo')
      expect(mop.regexp_field).to be_a Regexp
      expect(Mop.find(mop.id).regexp_field).to be_a Regexp
      expect(
        Mop.collection.find(
          "_id" => mop.id,
          "regexp_field" => { "$type" => 'regex' }
        ).count
      ).to be == 1
    end
  end

  context 'BSON::Regexp::Raw field' do
    it 'round-trips BSON::Regexp::Raws' do
      mop = Mop.create!(bson_regexp_field: BSON::Regexp::Raw.new('foo'))
      expect(mop.bson_regexp_field).to be_a BSON::Regexp::Raw
      expect(Mop.find(mop.id).bson_regexp_field).to be_a BSON::Regexp::Raw
      expect(
        Mop.collection.find(
          "_id" => mop.id,
          "bson_regexp_field" => { "$type" => 'regex' }
        ).count
      ).to be == 1
    end
  end
end
