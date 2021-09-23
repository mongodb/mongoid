# frozen_string_literal: true

require 'spec_helper'

describe 'TimeWithZone in queries' do
  let(:now_utc) { Time.now.utc }
  let(:now_in_zone) { now_utc.in_time_zone(time_zone) }

  shared_examples_for 'time zone queries' do
    let!(:book_earlier) { Book.create!(updated_at: now_utc - 20.minutes, dynamic_time: now_utc - 20.minutes).reload }
    let!(:book_now)     { Book.create!(dynamic_time: now_in_zone).reload }
    let!(:book_later)   { Book.create!(updated_at: now_in_zone + 20.minutes, dynamic_time: now_in_zone + 20.minutes).reload }

    context 'Mongo driver static field' do

      let(:view_lt) do
        Book.collection.find(updated_at: {'$lt' => query_time + 10.minutes})
      end

      let(:view_gt) do
        Book.collection.find(updated_at: {'$gt' => query_time - 10.minutes})
      end

      let(:view_range) do
        Book.collection.find(updated_at: {'$gt' => query_time - 10.minutes, '$lt' => query_time + 10.minutes})
      end

      it 'finds the document' do
        expect(view_lt.to_a).to eq([book_earlier.attributes, book_now.attributes])
        expect(view_gt.to_a).to eq([book_now.attributes, book_later.attributes])
        expect(view_range.to_a).to eq([book_now.attributes])
      end
    end

    context 'Mongo driver dynamic field' do

      let(:view_lt) do
        Book.collection.find(dynamic_time: {'$lt' => query_time + 10.minutes})
      end

      let(:view_gt) do
        Book.collection.find(dynamic_time: {'$gt' => query_time - 10.minutes})
      end

      let(:view_range) do
        Book.collection.find(dynamic_time: {'$gt' => query_time - 10.minutes, '$lt' => query_time + 10.minutes})
      end

      it 'finds the document' do
        expect(view_lt.to_a).to eq([book_earlier.attributes, book_now.attributes])
        expect(view_gt.to_a).to eq([book_now.attributes, book_later.attributes])
        expect(view_range.to_a).to eq([book_now.attributes])
      end
    end

    context 'Mongoid static field' do

      let(:view_lt) do
        Book.all.lt(updated_at: query_time + 10.minutes)
      end

      let(:view_gt) do
        Book.all.gt(updated_at: query_time - 10.minutes)
      end

      let(:view_range) do
        Book.all.where(updated_at: (query_time - 10.minutes)..(query_time + 10.minutes))
      end

      it 'finds the document' do
        expect(view_lt.pluck(:_id).sort).to eq([book_earlier, book_now].pluck(:_id).sort)
        expect(view_gt.pluck(:_id).sort).to eq([book_now, book_later].pluck(:_id).sort)
        expect(view_range.pluck(:_id).sort).to eq([book_now].pluck(:_id).sort)
      end
    end

    context 'Mongoid dynamic field' do

      let(:view_lt) do
        Book.all.lt(dynamic_time: query_time + 10.minutes)
      end

      let(:view_gt) do
        Book.all.gt(dynamic_time: query_time - 10.minutes)
      end

      let(:view_range) do
        Book.all.where(dynamic_time: (query_time - 10.minutes)..(query_time + 10.minutes))
      end

      it 'finds the document' do
        expect(view_lt.pluck(:_id).sort).to eq([book_earlier, book_now].pluck(:_id).sort)
        expect(view_gt.pluck(:_id).sort).to eq([book_now, book_later].pluck(:_id).sort)
        expect(view_range.pluck(:_id).sort).to eq([book_now].pluck(:_id).sort)
      end
    end
  end

  context 'query with Time' do
    let(:query_time) { now_utc }

    context 'when zone of queried time is UTC' do
      let(:time_zone) { 'UTC' }
      it { expect(now_in_zone.utc_offset).to eq 0 }
      it_behaves_like 'time zone queries'
    end

    context 'when zone of queried time is JST' do
      let(:time_zone) { 'Asia/Tokyo' }
      it { expect(now_in_zone.utc_offset).to be > 0 }
      it_behaves_like 'time zone queries'
    end

    context 'when zone of queried time is PST' do
      let(:time_zone) { 'Pacific Time (US & Canada)' }
      it { expect(now_in_zone.utc_offset).to be < 0 }
      it_behaves_like 'time zone queries'
    end
  end

  context 'query with ActiveSupport::TimeWithZone' do
    let(:query_time) { now_in_zone }

    context 'when zone of queried time is UTC' do
      let(:time_zone) { 'UTC' }
      it { expect(now_in_zone.utc_offset).to eq 0 }
      it_behaves_like 'time zone queries'
    end

    context 'when zone of queried time is JST' do
      let(:time_zone) { 'Asia/Tokyo' }
      it { expect(now_in_zone.utc_offset).to be > 0 }
      it_behaves_like 'time zone queries'
    end

    context 'when zone of queried time is PST' do
      let(:time_zone) { 'Pacific Time (US & Canada)' }
      it { expect(now_in_zone.utc_offset).to be < 0 }
      it_behaves_like 'time zone queries'
    end
  end
end
