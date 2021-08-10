# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'TimeWithZone in queries' do
  let(:now_utc) { Time.now.utc }
  let(:now_in_zone) { now_utc.in_time_zone(time_zone) }

  shared_examples_for 'time zone queries' do
    let!(:agency1) { Agency.create!(updated_at: now_utc - 20.minutes, dynamic_time: now_utc - 20.minutes).reload }
    let!(:agency2) { Agency.create!(dynamic_time: now_in_zone).reload }
    let!(:agency3) { Agency.create!(updated_at: now_in_zone + 20.minutes, dynamic_time: now_in_zone + 20.minutes).reload }

    context 'Mongo driver static field' do

      let(:view_lt) do
        Agency.collection.find(updated_at: {'$lt' => query_time + 10.minutes})
      end

      let(:view_gt) do
        Agency.collection.find(updated_at: {'$gt' => query_time - 10.minutes})
      end

      let(:view_range) do
        Agency.collection.find(updated_at: {'$gt' => query_time - 10.minutes, '$lt' => query_time + 10.minutes})
      end

      it 'finds the document' do
        expect(view_lt.to_a).to eq([agency1.attributes, agency2.attributes])
        expect(view_gt.to_a).to eq([agency2.attributes, agency3.attributes])
        expect(view_range.to_a).to eq([agency2.attributes])
      end
    end

    context 'Mongo driver dynamic field' do

      let(:view_lt) do
        Agency.collection.find(dynamic_time: {'$lt' => query_time + 10.minutes})
      end

      let(:view_gt) do
        Agency.collection.find(dynamic_time: {'$gt' => query_time - 10.minutes})
      end

      let(:view_range) do
        Agency.collection.find(dynamic_time: {'$gt' => query_time - 10.minutes, '$lt' => query_time + 10.minutes})
      end

      it 'finds the document' do
        expect(view_lt.to_a).to eq([agency1.attributes, agency2.attributes])
        expect(view_gt.to_a).to eq([agency2.attributes, agency3.attributes])
        expect(view_range.to_a).to eq([agency2.attributes])
      end
    end

    context 'Mongoid static field' do

      let(:view_lt) do
        Agency.all.lt(updated_at: query_time + 10.minutes)
      end

      let(:view_gt) do
        Agency.all.gt(updated_at: query_time - 10.minutes)
      end

      let(:view_range) do
        Agency.all.where(updated_at: (query_time - 10.minutes)..(query_time + 10.minutes))
      end

      it 'finds the document' do
        expect(view_lt.pluck(:_id).sort).to eq([agency1, agency2].pluck(:_id).sort)
        expect(view_gt.pluck(:_id).sort).to eq([agency2, agency3].pluck(:_id).sort)
        expect(view_range.pluck(:_id).sort).to eq([agency2].pluck(:_id).sort)
      end
    end

    context 'Mongoid dynamic field' do

      let(:view_lt) do
        Agency.all.lt(dynamic_time: query_time + 10.minutes)
      end

      let(:view_gt) do
        Agency.all.gt(dynamic_time: query_time - 10.minutes)
      end

      let(:view_range) do
        Agency.all.where(dynamic_time: (query_time - 10.minutes)..(query_time + 10.minutes))
      end

      it 'finds the document' do
        expect(view_lt.pluck(:_id).sort).to eq([agency1, agency2].pluck(:_id).sort)
        expect(view_gt.pluck(:_id).sort).to eq([agency2, agency3].pluck(:_id).sort)
        expect(view_range.pluck(:_id).sort).to eq([agency2].pluck(:_id).sort)
      end
    end
  end

  context 'query with Time' do
    let(:query_time) { now_utc }

    context 'in a UTC time zone' do
      let(:time_zone) { 'UTC' }
      it { expect(now_in_zone.utc_offset).to eq 0 }
      it_behaves_like 'time zone queries'
    end

    context 'in a JST time zone' do
      let(:time_zone) { 'Asia/Tokyo' }
      it { expect(now_in_zone.utc_offset).to be > 0 }
      it_behaves_like 'time zone queries'
    end

    context 'in a PST time zone' do
      let(:time_zone) { 'Pacific Time (US & Canada)' }
      it { expect(now_in_zone.utc_offset).to be < 0 }
      it_behaves_like 'time zone queries'
    end
  end

  context 'query with ActiveSupport::TimeWithZone' do
    let(:query_time) { now_in_zone }

    context 'in a UTC time zone' do
      let(:time_zone) { 'UTC' }
      it { expect(now_in_zone.utc_offset).to eq 0 }
      it_behaves_like 'time zone queries'
    end

    context 'in a JST time zone' do
      let(:time_zone) { 'Asia/Tokyo' }
      it { expect(now_in_zone.utc_offset).to be > 0 }
      it_behaves_like 'time zone queries'
    end

    context 'in a PST time zone' do
      let(:time_zone) { 'Pacific Time (US & Canada)' }
      it { expect(now_in_zone.utc_offset).to be < 0 }
      it_behaves_like 'time zone queries'
    end
  end
end
