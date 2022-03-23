# frozen_string_literal: true

require 'spec_helper'

describe 'Queries with Range criteria' do
  let(:now_utc) { Time.utc(2020, 1, 1, 16, 0, 0, 0) }
  let(:now_in_zone) { now_utc.in_time_zone('Asia/Tokyo') }
  let(:today) { Date.new(2020, 1, 1) }

  let(:labels) do
    [ Label.new(age: 12), Label.new(age: 16) ]
  end

  let!(:band1) { Band.create!(likes: 0, rating: 0.9, founded: today, updated_at: now_utc) }
  let!(:band2) { Band.create!(likes: 1, rating: 1.0, founded: today + 1.day, updated_at: now_utc + 1.days) }
  let!(:band3) { Band.create!(likes: 2, rating: 2.9, founded: today + 2.days, updated_at: now_utc + 2.days) }
  let!(:band4) { Band.create!(likes: 3, rating: 3.0, founded: today + 3.days, updated_at: now_utc + 3.days) }
  let!(:band5) { Band.create!(likes: 4, rating: 3.1, founded: today + 4.days, updated_at: now_utc + 4.days, labels: labels) }

  context 'Range<Integer> criteria vs Integer field' do

    it 'returns objects within the range' do
      expect(Band.where(likes: 1..3).to_a).to eq [band2, band3, band4]
      expect(Band.where(likes: 1...3).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(likes: eval('1..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(likes: eval('..3')).to_a).to eq [band1, band2, band3, band4]
        expect(Band.where(likes: eval('...3')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<Integer> criteria vs Float field' do

    it 'returns objects within the range' do
      expect(Band.where(rating: 1..3).to_a).to eq [band2, band3, band4]
      expect(Band.where(rating: 1...3).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(rating: eval('1..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(rating: eval('..3')).to_a).to eq [band1, band2, band3, band4]
        expect(Band.where(rating: eval('...3')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<Float> criteria vs Integer field' do

    it 'returns objects within the range' do
      expect(Band.where(likes: 0.95..3.05).to_a).to eq [band2, band3, band4]
      expect(Band.where(likes: 0.95...3.0).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(likes: eval('0.95..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(likes: eval('..3.05')).to_a).to eq [band1, band2, band3, band4]
        expect(Band.where(likes: eval('...3.0')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<Float> criteria vs Float field' do

    it 'returns objects within the range' do
      expect(Band.where(rating: 0.95..3.05).to_a).to eq [band2, band3, band4]
      expect(Band.where(rating: 0.95...3.0).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(rating: eval('0.95..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(rating: eval('..3.05')).to_a).to eq [band1, band2, band3, band4]
        expect(Band.where(rating: eval('...3.0')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<Time> criteria vs Time field' do

    it 'returns objects within the range' do
      expect(Band.where(updated_at: (now_utc + 1.day)..(now_utc + 3.days)).to_a).to eq [band2, band3, band4]
      expect(Band.where(updated_at: (now_utc + 1.day)...(now_utc + 3.days)).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(updated_at: eval('(now_utc + 1.day)..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(updated_at: eval('..(now_utc + 3.days)')).to_a).to eq [band1, band2, band3, band4]
        expect(Band.where(updated_at: eval('...(now_utc + 3.days)')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<Time> criteria vs Date field' do

    it 'returns objects within the range' do
      expect(Band.where(founded: (now_utc + 1.day)..(now_utc + 3.days)).to_a).to eq [band2, band3, band4]
      expect(Band.where(founded: (now_utc + 1.day)...(now_utc + 3.days)).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(founded: eval('(now_utc + 1.day)..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(founded: eval('..(now_utc + 3.days)')).to_a).to eq [band1, band2, band3, band4]
        expect(Band.where(founded: eval('...(now_utc + 3.days)')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<ActiveSupport::TimeWithZone> criteria vs Time field' do

    it 'returns objects within the range' do
      expect(Band.where(updated_at: (now_in_zone + 1.day)..(now_in_zone + 3.days)).to_a).to eq [band2, band3, band4]
      expect(Band.where(updated_at: (now_in_zone + 1.day)...(now_in_zone + 3.days)).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(updated_at: eval('(now_in_zone + 1.day)..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(updated_at: eval('..(now_in_zone + 3.days)')).to_a).to eq [band1, band2, band3, band4]
        expect(Band.where(updated_at: eval('...(now_in_zone + 3.days)')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<ActiveSupport::TimeWithZone> criteria vs Date field' do

    it 'returns objects within the range' do
      expect(Band.where(founded: (now_in_zone + 1.day)..(now_in_zone + 3.days)).to_a).to eq [band3, band4, band5]
      expect(Band.where(founded: (now_in_zone + 1.day)...(now_in_zone + 3.days)).to_a).to eq [band3, band4]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(founded: eval('(now_in_zone + 1.day)..')).to_a).to eq [band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(founded: eval('..(now_in_zone + 3.days)')).to_a).to eq [band1, band2, band3, band4, band5]
        expect(Band.where(founded: eval('...(now_in_zone + 3.days)')).to_a).to eq [band1, band2, band3, band4]
      end
    end
  end

  context 'Range<Date> criteria vs Date field' do

    it 'returns objects within the range' do
      expect(Band.where(founded: (today + 1.day)..(today + 3.days)).to_a).to eq [band2, band3, band4]
      expect(Band.where(founded: (today + 1.day)...(today + 3.days)).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(founded: eval('(today + 1.day)..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(founded: eval('..(today + 3.days)')).to_a).to eq [band1, band2, band3, band4]
        expect(Band.where(founded: eval('...(today + 3.days)')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<Date> criteria vs Time field' do

    it 'returns objects within the range' do
      expect(Band.where(updated_at: (today + 1.day)..(today + 3.days)).to_a).to eq [band2, band3]
      expect(Band.where(updated_at: (today + 1.day)...(today + 3.days)).to_a).to eq [band2, band3]
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where(updated_at: eval('(today + 1.day)..')).to_a).to eq [band2, band3, band4, band5]
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where(updated_at: eval('..(today + 3.days)')).to_a).to eq [band1, band2, band3]
        expect(Band.where(updated_at: eval('...(today + 3.days)')).to_a).to eq [band1, band2, band3]
      end
    end
  end

  context 'Range<Integer> criteria vs embedded Integer field' do

    it 'returns objects within the range' do
      expect(Band.where("labels.age" => 10..18).to_a).to eq [band5]
      expect(Band.where("labels.age" => 13...16).to_a).to eq []
    end

    it "does not return objects out of range" do
      expect(Band.where("labels.age" => 13..14).to_a).to eq []
    end

    context 'endless range' do
      ruby_version_gte '2.6'

      it 'returns all objects above the value' do
        expect(Band.where("labels.age": eval('1..')).to_a).to eq [band5]
      end

      it 'does not return the objects under the value' do
        expect(Band.where("labels.age": eval('100..')).to_a).to eq []
      end
    end

    context 'beginless range' do
      ruby_version_gte '2.7'

      it 'returns all objects under the value' do
        expect(Band.where("labels.age": eval('..16')).to_a).to eq [band5]
      end
      it 'does not return the objects above the value' do
        expect(Band.where("labels.age": eval('...12')).to_a).to eq []
      end
    end
  end

  context 'Range<Integer> criteria vs Array<Integer>' do
    let!(:band6) { Band.create!(genres: [12, 16]) }

    it 'returns objects within the range' do
      expect(Band.where("genres" => 10..18).to_a).to eq [band6]
    end

    it "does not return objects out of range" do
      expect(Band.where("genres" => 13..14).to_a).to eq []
    end
  end

  context 'Range<Integer> criteria vs aliased Array<Integer>' do
    let!(:person) { Person.create!(array: [12, 16]) }

    it 'returns objects within the range' do
      expect(Person.where("array" => 10..18).to_a).to eq [person]
    end

    it "does not return objects out of range" do
      expect(Person.where("array" => 13..14).to_a).to eq []
    end
  end

  context 'Range<Integer> criteria vs Array<Hash<Symbol, Integer>>' do
    let!(:band6) { Band.create!(genres: [{x: 12}, {x: 16}]) }

    it 'returns objects within the range' do
      expect(Band.where("genres.x" => 10..18).to_a).to eq [band6]
    end

    it "does not return objects out of range" do
      expect(Band.where("genres.x" => 13..14).to_a).to eq []
    end
  end

  context 'Range<Integer> criteria vs aliased/doubly embedded Integer' do
    let!(:person) do
      Person.create!(passport: Passport.new).tap do |b|
        b.passport.passport_pages.create!(num_stamps: 12)
        b.passport.passport_pages.create!(num_stamps: 16)
      end
    end

    config_override :broken_alias_handling, false

    it 'returns objects within the range' do
      expect(Person.where("passport.passport_pages.num_stamps" => 10..18).to_a).to eq [person]
    end

    it "does not return objects out of range" do
      expect(Person.where("passport.passport_pages.num_stamps" => 13..14).to_a).to eq []
    end
  end
end
