# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'
begin
  require 'active_job'
  require 'mongoid/railties/bson_object_id_serializer'

  describe 'ActiveJob Serialization' do
    skip unless defined?(ActiveJob)

    class TestBsonObjectIdSerializerJob < ActiveJob::Base
      def perform(*args)
        args
      end
    end

    let(:band) do
      Band.create!
    end

    before do
      ActiveJob::Serializers.add_serializers(
        [::Mongoid::Railties::ActiveJobSerializers::BsonObjectIdSerializer]
      )
    end

    it 'serializes and deserializes BSON::ObjectId' do
      expect do
        TestBsonObjectIdSerializerJob.perform_later(band.id)
      end.not_to raise_error
    end
  end
rescue LoadError
  RSpec.context.skip 'This test requires active_job'
end
