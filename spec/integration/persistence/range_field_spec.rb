# frozen_string_literal: true

require 'spec_helper'

describe 'Range field persistence' do
  let!(:person) { Person.create!(field => value).reload }
  subject { person.send(field) }
  let(:now_utc) { Time.now }
  let(:later_utc) { now_utc + 10.minutes }
  let(:now_in_zone) { now_utc.in_time_zone('Asia/Tokyo') }
  let(:later_in_zone) { later_utc.in_time_zone('Asia/Tokyo') }

  context 'static field' do
    let(:field) { :range }

    context 'when Integer' do
      let(:value) { 1..3 }
      it do
        expect(subject).to eq(1..3)
      end
    end

    context 'when Integer exclude_end' do
      let(:value) { 1...3 }
      it { expect(subject).to eq(1...3) }
    end

    context 'when endless' do
      ruby_version_gte '2.6'
      let(:value) { eval('3..') }
      it { expect(subject).to eq(eval('3..')) }
    end

    context 'when endless exclude_end' do
      ruby_version_gte '2.6'
      let(:value) { eval('3...') }
      it { expect(subject).to eq(eval('3...')) }
    end

    context 'when beginning-less' do
      ruby_version_gte '2.7'
      let(:value) { eval('..3') }
      it { expect(subject).to eq(eval('..3')) }
    end

    context 'when beginning-less exclude_end' do
      ruby_version_gte '2.7'
      let(:value) { eval('...3') }
      it { expect(subject).to eq(eval('...3')) }
    end

    context 'when Hash<String, Integer>' do
      let(:value) { { 'min' => 1, 'max' => 3 } }
      it { expect(subject).to eq(1..3) }
    end

    context 'when Hash<String, Integer> exclude_end' do
      let(:value) { { 'min' => 1, 'max' => 3, 'exclude_end' => true } }
      it { expect(subject).to eq(1...3) }
    end

    context 'when Hash<Symbol, Integer>' do
      let(:value) { { min: 1, max: 3 } }
      it { expect(subject).to eq(1..3) }
    end

    context 'when Hash<Symbol, Integer> exclude_end' do
      let(:value) { { min: 1, max: 3, exclude_end: true } }
      it { expect(subject).to eq(1...3) }
    end

    context 'when Time' do
      let(:value) { now_utc..later_utc }

      it do
        expect(subject).to be_a Range
        expect(subject.exclude_end?).to eq false
        expect(subject.first).to be_within(0.01.second).of(now_utc)
        expect(subject.last).to be_within(0.01.second).of(later_utc)
        expect(subject.first.class).to eq Time
        expect(subject.last.class).to eq Time
      end
    end

    context 'when Time exclude_end' do
      let(:value) { now_utc...later_utc }

      it do
        expect(subject).to be_a Range
        expect(subject.exclude_end?).to eq true
        expect(subject.first).to be_within(0.01.second).of(now_utc)
        expect(subject.last).to be_within(0.01.second).of(later_utc)
        expect(subject.first.class).to eq Time
        expect(subject.last.class).to eq Time
      end
    end

    context 'when Hash<String, Time>' do
      let(:value) { { 'min' => now_utc, 'max' => later_utc } }

      it do
        expect(subject).to be_a Range
        expect(subject.exclude_end?).to eq false
        expect(subject.first).to be_within(0.01.second).of(now_utc)
        expect(subject.last).to be_within(0.01.second).of(later_utc)
        expect(subject.first.class).to eq Time
        expect(subject.last.class).to eq Time
      end
    end

    context 'when Hash<String, Time> exclude_end' do
      let(:value) { { 'min' => now_utc, 'max' => later_utc, 'exclude_end' => true } }

      it do
        expect(subject).to be_a Range
        expect(subject.exclude_end?).to eq true
        expect(subject.first).to be_within(0.01.second).of(now_utc)
        expect(subject.last).to be_within(0.01.second).of(later_utc)
        expect(subject.first.class).to eq Time
        expect(subject.last.class).to eq Time
      end
    end

    context 'when ActiveSupport::TimeWithZone' do
      let(:value) { now_in_zone..later_in_zone }

      it do
        expect(subject).to be_a Range
        expect(subject.exclude_end?).to eq false
        expect(subject.first).to be_within(0.01.second).of(now_utc)
        expect(subject.last).to be_within(0.01.second).of(later_utc)
        expect(subject.first.class).to eq Time
        expect(subject.last.class).to eq Time
      end
    end

    context 'when ActiveSupport::TimeWithZone exclude_end' do
      let(:value) { now_in_zone...later_in_zone }

      it do
        expect(subject).to be_a Range
        expect(subject.exclude_end?).to eq true
        expect(subject.first).to be_within(0.01.second).of(now_utc)
        expect(subject.last).to be_within(0.01.second).of(later_utc)
        expect(subject.first.class).to eq Time
        expect(subject.last.class).to eq Time
      end
    end

    context 'when Hash<String, ActiveSupport::TimeWithZone>' do
      let(:value) { { 'min' => now_in_zone, 'max' => later_in_zone } }

      it do
        expect(subject).to be_a Range
        expect(subject.exclude_end?).to eq false
        expect(subject.first).to be_within(0.01.second).of(now_utc)
        expect(subject.last).to be_within(0.01.second).of(later_utc)
        expect(subject.first.class).to eq Time
        expect(subject.last.class).to eq Time
      end
    end

    context 'when Hash<String, ActiveSupport::TimeWithZone> exclude_end' do
      let(:value) { { 'min' => now_in_zone, 'max' => later_in_zone, 'exclude_end' => true } }

      it do
        expect(subject).to be_a Range
        expect(subject.exclude_end?).to eq true
        expect(subject.first).to be_within(0.01.second).of(now_utc)
        expect(subject.last).to be_within(0.01.second).of(later_utc)
        expect(subject.first.class).to eq Time
        expect(subject.last.class).to eq Time
      end
    end
  end

  context 'dynamic field' do
    let(:field) { :dynamic }

    context 'when Integer' do
      let(:value) { 1..3 }
      it do
        expect(subject).to eq('max' => 3, 'min' => 1)
      end
    end

    context 'when Integer exclude_end' do
      let(:value) { 1...3 }
      it { expect(subject).to eq('max' => 3, 'min' => 1, 'exclude_end' => true) }
    end

    context 'when descending' do
      let(:value) { 3..1 }
      it { expect(subject).to eq('max' => 1, 'min' => 3) }
    end

    context 'when descending exclude_end' do
      let(:value) { 3...1 }
      it { expect(subject).to eq('max' => 1, 'min' => 3, 'exclude_end' => true) }
    end

    context 'when endless' do
      ruby_version_gte '2.6'
      let(:value) { eval('3..') }
      it { expect(subject).to eq('min' => 3) }
    end

    context 'when endless exclude_end' do
      ruby_version_gte '2.6'
      let(:value) { eval('3...') }
      it { expect(subject).to eq('min' => 3, 'exclude_end' => true) }
    end

    context 'when beginning-less' do
      ruby_version_gte '2.7'
      let(:value) { eval('..3') }
      it { expect(subject).to eq('max' => 3) }
    end

    context 'when beginning-less exclude_end' do
      ruby_version_gte '2.7'
      let(:value) { eval('...3') }
      it { expect(subject).to eq('max' => 3, 'exclude_end' => true) }
    end

    context 'when Hash<String, Integer>' do
      let(:value) { { 'min' => 1, 'max' => 3 } }
      it { expect(subject).to eq('max' => 3, 'min' => 1) }
    end

    context 'when Hash<String, Integer> exclude_end' do
      let(:value) { { 'min' => 1, 'max' => 3, 'exclude_end' => true } }
      it { expect(subject).to eq('max' => 3, 'min' => 1, 'exclude_end' => true) }
    end

    context 'when Hash<Symbol, Integer>' do
      let(:value) { { min: 1, max: 3 } }
      it { expect(subject).to eq('max' => 3, 'min' => 1) }
    end

    context 'when Hash<Symbol, Integer> exclude_end' do
      let(:value) { { min: 1, max: 3, exclude_end: true } }
      it { expect(subject).to eq('max' => 3, 'min' => 1, 'exclude_end' => true) }
    end

    context 'when Time' do
      let(:value) { now_utc..later_utc }

      it do
        expect(subject).to be_a Hash
        expect(subject['exclude_end']).to eq nil
        expect(subject['min']).to be_within(0.01.second).of(now_utc)
        expect(subject['max']).to be_within(0.01.second).of(later_utc)
        expect(subject['min'].class).to eq Time
        expect(subject['max'].class).to eq Time
      end
    end

    context 'when Time exclude_end' do
      let(:value) { now_utc...later_utc }

      it do
        expect(subject).to be_a Hash
        expect(subject['exclude_end']).to eq true
        expect(subject['min']).to be_within(0.01.second).of(now_utc)
        expect(subject['max']).to be_within(0.01.second).of(later_utc)
        expect(subject['min'].class).to eq Time
        expect(subject['max'].class).to eq Time
      end
    end

    context 'when Hash<String, Time>' do
      let(:value) { { 'min' => now_utc, 'max' => later_utc } }

      it do
        expect(subject).to be_a Hash
        expect(subject['exclude_end']).to eq nil
        expect(subject['min']).to be_within(0.01.second).of(now_utc)
        expect(subject['max']).to be_within(0.01.second).of(later_utc)
        expect(subject['min'].class).to eq Time
        expect(subject['max'].class).to eq Time
      end
    end

    context 'when Hash<String, Time> exclude_end' do
      let(:value) { { 'min' => now_utc, 'max' => later_utc, 'exclude_end' => true } }

      it do
        expect(subject).to be_a Hash
        expect(subject['exclude_end']).to eq true
        expect(subject['min']).to be_within(0.01.second).of(now_utc)
        expect(subject['max']).to be_within(0.01.second).of(later_utc)
        expect(subject['min'].class).to eq Time
        expect(subject['max'].class).to eq Time
      end
    end

    context 'when ActiveSupport::TimeWithZone' do
      let(:value) { now_in_zone..later_in_zone }

      it do
        expect(subject).to be_a Hash
        expect(subject['exclude_end']).to eq nil
        expect(subject['min']).to be_within(0.01.second).of(now_utc)
        expect(subject['max']).to be_within(0.01.second).of(later_utc)
        expect(subject['min'].class).to eq Time
        expect(subject['max'].class).to eq Time
      end
    end

    context 'when ActiveSupport::TimeWithZone exclude_end' do
      let(:value) { now_in_zone...later_in_zone }

      it do
        expect(subject).to be_a Hash
        expect(subject['exclude_end']).to eq true
        expect(subject['min']).to be_within(0.01.second).of(now_utc)
        expect(subject['max']).to be_within(0.01.second).of(later_utc)
        expect(subject['min'].class).to eq Time
        expect(subject['max'].class).to eq Time
      end
    end

    context 'when Hash<String, ActiveSupport::TimeWithZone>' do
      let(:value) { { 'min' => now_in_zone, 'max' => later_in_zone } }

      it do
        expect(subject).to be_a Hash
        expect(subject['exclude_end']).to eq nil
        expect(subject['min']).to be_within(0.01.second).of(now_utc)
        expect(subject['max']).to be_within(0.01.second).of(later_utc)
        expect(subject['min'].class).to eq Time
        expect(subject['max'].class).to eq Time
      end
    end

    context 'when Hash<String, ActiveSupport::TimeWithZone> exclude_end' do
      let(:value) { { 'min' => now_in_zone, 'max' => later_in_zone, 'exclude_end' => true } }

      it do
        expect(subject).to be_a Hash
        expect(subject['exclude_end']).to eq true
        expect(subject['min']).to be_within(0.01.second).of(now_utc)
        expect(subject['max']).to be_within(0.01.second).of(later_utc)
        expect(subject['min'].class).to eq Time
        expect(subject['max'].class).to eq Time
      end
    end
  end
end
