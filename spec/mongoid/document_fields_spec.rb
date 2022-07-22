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
        registry.data.should be_a(BSON::Binary)
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.data.should == BSON::Binary.new(data)
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
        registry.data.should be nil
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.data.should be nil
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
        registry.data.should be nil
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.data.should be nil
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

        obj_id.should_not be_frozen
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.obj_id.should == obj_id
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
        registry.obj_id.should be_a(BSON::ObjectId)
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.obj_id.should == BSON::ObjectId.from_string(obj_id)
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
        registry.obj_id.should be nil
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.obj_id.should be nil
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
        registry.obj_id.should == "hello"
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.obj_id.should == "hello"
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
        registry.obj_id.should == :sym
      end

      it 'persists' do
        registry.save!

        _registry = Registry.find(registry.id)
        _registry.obj_id.should == :sym
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
