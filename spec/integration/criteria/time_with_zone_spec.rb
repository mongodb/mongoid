# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'TimeWithZone in queries' do
  context 'in a non-UTC time zone' do
    let(:time_zone_name) { 'Pacific Time (US & Canada)' }

    before do
      time = Time.now
      expect(time.utc_offset).not_to eq(time.in_time_zone(time_zone_name).utc_offset)
    end

    let(:time_in_zone) { Time.now.in_time_zone(time_zone_name) }

    let(:view_lt) do
      Agency.collection.find(updated_at: {'$lt' => time_in_zone + 10.minutes})
    end

    let(:view_gt) do
      Agency.collection.find(updated_at: {'$gt' => time_in_zone - 10.minutes})
    end

    let!(:agency) { Agency.create!.reload }

    it 'finds the document' do
      view_lt.to_a.should == [agency.attributes]
      view_gt.to_a.should == [agency.attributes]
    end
  end
end
