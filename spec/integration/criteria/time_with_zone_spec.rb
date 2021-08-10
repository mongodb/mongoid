# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'TimeWithZone in queries' do
  let(:now_utc) { Time.now.utc }
  let(:now_in_zone) { now_utc.in_time_zone(time_zone_name) }

  shared_examples_for 'time zone queries' do
    let!(:agency1) { Agency.create!(updated_at: Time.current - 20.minutes).reload }
    let!(:agency2) { Agency.create!.reload }
    let!(:agency3) { Agency.create!(updated_at: Time.current + 20.minutes).reload }

    context 'Mongo driver queries' do

      let(:view_lt) do
        Agency.collection.find(updated_at: {'$lt' => now_in_zone + 10.minutes})
      end

      let(:view_gt) do
        Agency.collection.find(updated_at: {'$gt' => now_in_zone - 10.minutes})
      end

      let(:view_range) do
        Agency.collection.find(updated_at: {'$gt' => now_in_zone - 10.minutes, '$lt' => now_in_zone + 10.minutes})
      end

      it 'finds the document' do
        expect(view_lt.to_a).to eq([agency1.attributes, agency2.attributes])
        expect(view_gt.to_a).to eq([agency2.attributes, agency3.attributes])
        expect(view_range.to_a).to eq([agency2.attributes])
      end
    end

    context 'Mongoid queries' do

      let(:view_lt) do
        Agency.all.lt(updated_at: now_in_zone + 10.minutes)
      end

      let(:view_gt) do
        Agency.all.gt(updated_at: now_in_zone - 10.minutes)
      end

      let(:view_range) do
        Agency.all.where(updated_at: (now_in_zone - 10.minutes)..(now_in_zone + 10.minutes))
      end

      it 'finds the document' do
        expect(view_lt.pluck(:_id).sort).to eq([agency1, agency2].pluck(:_id).sort)
        expect(view_gt.pluck(:_id).sort).to eq([agency2, agency3].pluck(:_id).sort)
        expect(view_range.pluck(:_id).sort).to eq([agency2].pluck(:_id).sort)
      end
    end
  end

  context 'in a UTC time zone' do
    let(:time_zone_name) { 'UTC' }
    it { expect(now_in_zone.utc_offset).to eq 0 }
    it_behaves_like 'time zone queries'
  end

  context 'in a JST time zone' do
    let(:time_zone_name) { 'Asia/Tokyo' }
    it { expect(now_in_zone.utc_offset).to be > 0 }
    it_behaves_like 'time zone queries'
  end

  context 'in a PST time zone' do
    let(:time_zone_name) { 'Pacific Time (US & Canada)' }
    it { expect(now_in_zone.utc_offset).to be < 0 }
    it_behaves_like 'time zone queries'
  end
end
