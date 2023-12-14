# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'
require 'active_job'
require 'mongoid/railties/bson_object_id_serializer'

describe 'Mongoid::Railties::ActiveJobSerializers::BsonObjectIdSerializer' do

  let(:serializer) { Mongoid::Railties::ActiveJobSerializers::BsonObjectIdSerializer.instance }
  let(:object_id) { BSON::ObjectId.new }

  describe '#serialize' do
    it 'serializes BSON::ObjectId' do
      expect(serializer.serialize(object_id)).to be_a(String)
    end
  end

  describe '#deserialize' do
    it 'deserializes BSON::ObjectId' do
      expect(serializer.deserialize(serializer.serialize(object_id))).to eq(object_id)
    end
  end
end
