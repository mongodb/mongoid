# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'Queries on Date fields' do
  let(:query) do
    Band.where(founded: arg)
  end

  let(:selector) { query.selector }

  shared_examples 'converts to beginning of day in UTC' do
    it 'converts to beginning of day in UTC' do
      selector['founded'].should == arg.dup.beginning_of_day.utc.beginning_of_day
    end
  end

  context 'using Time' do
    let(:arg) do
      Time.now.freeze
    end

    it_behaves_like 'converts to beginning of day in UTC'
  end

  context 'using TimeWithZone' do
    let(:time_zone_name) { 'Pacific Time (US & Canada)' }
    let(:arg) { Time.now.in_time_zone(time_zone_name).freeze }

    it_behaves_like 'converts to beginning of day in UTC'
  end

  context 'using DateTime' do
    let(:arg) do
      DateTime.now.freeze
    end

    it_behaves_like 'converts to beginning of day in UTC'
  end
end
