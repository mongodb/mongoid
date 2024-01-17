# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'

describe 'Queries with Mongoid::RawValue criteria' do
  let(:now_utc) { Time.utc(2020, 1, 1, 16, 0, 0, 0) }
  let(:today) { Date.new(2020, 1, 1) }

  let(:labels) do
    [ Label.new(age: 12), Label.new(age: 16) ]
  end

  let!(:band1) { Band.create!(name: '1', likes: 0, rating: 0.9, sales: BigDecimal('90'), decibels: 20..80, founded: today, updated: now_utc) }
  let!(:band2) { Band.create!(name: '2', likes: 1, rating: 1.0, sales: BigDecimal('100'), decibels: 30..90, founded: today, updated: now_utc + 1.days) }
  let!(:band3) { Band.create!(name: '3', likes: 1, rating: 2.2, sales: BigDecimal('220'), decibels: 40..100, founded: today + 1.days, updated: now_utc + 2.days) }
  let!(:band4) { Band.create!(name: '3', likes: 2, rating: 3.1, sales: BigDecimal('310'), decibels: 50..120, founded: today + 1.days, updated: now_utc + 3.days) }
  let!(:band5) { Band.create!(name: '4', likes: 3, rating: 3.1, sales: BigDecimal('310'), decibels: 60..150, founded: today + 2.days, updated: now_utc + 3.days, labels: labels) }

  let!(:band6) do
    id = BSON::ObjectId.new
    Band.collection.insert_one(_id: id, name: 1, likes: '1', rating: '3.1', sales: '310', decibels: '90', founded: '2020-01-02', updated: '2020-01-04 16:00:00 UTC')
    Band.find(id)
  end

  let!(:band7) do
    id = BSON::ObjectId.new
    Band.collection.insert_one(_id: id, name: 1.0, decibels: 90.0, founded: 1577923200, updated: 1578153600)
    Band.find(id)
  end

  context 'Mongoid::RawValue<String> criteria' do

    context 'Integer field' do
      it 'does not match objects' do
        expect(Band.where(likes: Mongoid::RawValue('1')).to_a).to eq [band6]
      end
  
      it 'matches objects without raw value' do
        expect(Band.where(likes: '1').to_a).to eq [band2, band3]
      end
    end
  
    context 'Float field' do
      it 'does not match objects' do
        expect(Band.where(rating: Mongoid::RawValue('3.1')).to_a).to eq [band6]
      end
  
      it 'matches objects with value stored as Float' do
        expect(Band.where(rating: '3.1').to_a).to eq [band4, band5]
      end
    end

    context 'BigDecimal field' do
      it 'does not match objects with raw value' do
        expect(Band.where(sales: Mongoid::RawValue('310')).to_a).to eq [band6]
      end

      it 'matches objects with value stored as Decimal128' do
        expect(Band.where(sales: '310').to_a).to eq [band4, band5]
      end
    end
  
    context 'String field' do
      it 'matches objects' do
        expect(Band.where(name: Mongoid::RawValue('3')).to_a).to eq [band3, band4]
      end
  
      it 'matches objects without raw value' do
        expect(Band.where(name: '3').to_a).to eq [band3, band4]
      end
    end
  
    context 'Range field' do
      it 'does not match objects with raw value' do
        expect(Band.where(decibels: Mongoid::RawValue('90')).to_a).to eq [band6]
      end
  
      it 'matches objects without raw value because String cannot be evolved to Range' do
        expect(Band.where(decibels: '90').to_a).to eq [band6]
      end
    end

    context 'Date field' do
      it 'does not match objects with raw value' do
        expect(Band.where(founded: Mongoid::RawValue('2020-01-02')).to_a).to eq [band6]
      end

      it 'matches objects without raw value' do
        expect(Band.where(founded: '2020-01-02').to_a).to eq [band3, band4]
      end
    end

    context 'Time field' do
      it 'does not match objects with raw value' do
        expect(Band.where(updated: Mongoid::RawValue('2020-01-04 16:00:00 UTC')).to_a).to eq [band6]
      end

      it 'matches objects without raw value' do
        expect(Band.where(updated: '2020-01-04 16:00:00 UTC').to_a).to eq [band4, band5]
      end
    end
  end

  context 'Mongoid::RawValue<Integer>' do

    context 'Integer field' do
      it 'matches objects with raw value' do
        expect(Band.where(likes: Mongoid::RawValue(1)).to_a).to eq [band2, band3]
      end

      it 'matches objects without raw value' do
        expect(Band.where(likes: 1).to_a).to eq [band2, band3]
      end
    end

    context 'Float field' do
      it 'does not match objects with raw value' do
        expect(Band.where(rating: Mongoid::RawValue(1)).to_a).to eq [band2]
        expect(Band.where(rating: Mongoid::RawValue(3)).to_a).to eq []
      end

      it 'matches objects without raw value' do
        expect(Band.where(rating: 1).to_a).to eq [band2]
        expect(Band.where(rating: 3).to_a).to eq []
      end
    end

    context 'BigDecimal field' do
      it 'matches objects with raw value' do
        expect(Band.where(sales: Mongoid::RawValue(310)).to_a).to eq [band4, band5]
      end

      it 'matches objects without raw value' do
        expect(Band.where(sales: 310).to_a).to eq [band4, band5]
      end
    end

    context 'String field' do
      it 'matches objects with raw value' do
        expect(Band.where(name: Mongoid::RawValue(1)).to_a).to eq [band6, band7]
      end

      it 'matches objects without raw value' do
        expect(Band.where(name: 3).to_a).to eq [band3, band4]
      end
    end

    context 'Range field' do
      it 'does not match objects with raw value' do
        expect(Band.where(decibels: Mongoid::RawValue(90)).to_a).to eq [band7]
      end

      it 'matches objects without raw value because Integer cannot be evolved to Range' do
        expect(Band.where(decibels: 90).to_a).to eq [band7]
      end
    end

    context 'Date field' do
      it 'does not match objects with raw value' do
        expect(Band.where(founded: Mongoid::RawValue(1577923200)).to_a).to eq [band7]
      end

      it 'matches objects without raw value' do
        expect(Band.where(founded: 1577923200).to_a).to eq [band3, band4]
      end
    end

    context 'Time field' do
      it 'does not match objects with raw value' do
        expect(Band.where(updated: Mongoid::RawValue(1578153600)).to_a).to eq [band7]
      end

      it 'matches objects without raw value' do
        expect(Band.where(updated: 1578153600).to_a).to eq [band4, band5]
      end
    end
  end

  context 'Mongoid::RawValue<Float>' do

    context 'Integer field' do
      it 'does not match objects with raw value' do
        expect(Band.where(likes: Mongoid::RawValue(1.0)).to_a).to eq [band2, band3]
      end

      it 'matches objects without raw value' do
        expect(Band.where(likes: 1.0).to_a).to eq [band2, band3]
      end
    end

    context 'Float field' do
      it 'does not match objects with raw value' do
        expect(Band.where(rating: Mongoid::RawValue(3.1)).to_a).to eq [band4, band5]
      end

      it 'matches objects without raw value' do
        expect(Band.where(rating: 3.1).to_a).to eq [band4, band5]
      end
    end

    context 'BigDecimal field' do
      it 'matches objects with raw value' do
        expect(Band.where(sales: Mongoid::RawValue(310.0)).to_a).to eq [band4, band5]
      end

      it 'matches objects without raw value' do
        expect(Band.where(sales: 310.0).to_a).to eq [band4, band5]
      end
    end

    context 'String field' do
      it 'matches objects with raw value' do
        expect(Band.where(name: Mongoid::RawValue(1.0)).to_a).to eq [band6, band7]
      end

      it 'matches objects without raw value' do
        expect(Band.where(name: 1.0).to_a).to eq []
      end
    end

    context 'Range field' do
      it 'does not match objects with raw value' do
        expect(Band.where(decibels: Mongoid::RawValue(90.0)).to_a).to eq [band7]
      end

      it 'matches objects without raw value because Float cannot be evolved to Range' do
        expect(Band.where(decibels: 90.0).to_a).to eq [band7]
      end
    end

    context 'Date field' do
      it 'does not match objects with raw value' do
        expect(Band.where(founded: Mongoid::RawValue(1577923200.0)).to_a).to eq [band7]
      end

      it 'matches objects without raw value' do
        expect(Band.where(founded: 1577923200.0).to_a).to eq [band3, band4]
      end
    end

    context 'Time field' do
      it 'does not match objects with raw value' do
        expect(Band.where(updated: Mongoid::RawValue(1578153600.0)).to_a).to eq [band7]
      end

      it 'matches objects without raw value' do
        expect(Band.where(updated: 1578153600.0).to_a).to eq [band4, band5]
      end
    end
  end

  context 'Mongoid::RawValue<BigDecimal>' do

    context 'Integer field' do
      it 'does not match objects with raw value' do
        expect(Band.where(likes: Mongoid::RawValue(BigDecimal('1'))).to_a).to eq [band2, band3]
      end

      it 'matches objects without raw value' do
        expect(Band.where(likes: BigDecimal('1')).to_a).to eq [band2, band3]
      end
    end

    context 'Float field' do
      it 'does not exact match objects with raw value due to float imprecision' do
        expect(Band.where(rating: Mongoid::RawValue(BigDecimal('3.1'))).to_a).to eq []
      end

      it 'fuzzy matches objects with raw value' do
        expect(Band.gte(rating: Mongoid::RawValue(BigDecimal('3.099'))).lte(rating: Mongoid::RawValue(BigDecimal('3.101'))).to_a).to eq [band4, band5]
      end

      it 'matches objects without raw value' do
        expect(Band.where(rating: BigDecimal('3.1')).to_a).to eq [band4, band5]
      end
    end

    context 'BigDecimal field' do
      it 'matches objects with raw value' do
        expect(Band.where(sales: Mongoid::RawValue(BigDecimal('310'))).to_a).to eq [band4, band5]
      end

      it 'matches objects without raw value' do
        expect(Band.where(sales: BigDecimal('310')).to_a).to eq [band4, band5]
      end
    end

    context 'String field' do
      it 'matches objects with raw value' do
        expect(Band.where(name: Mongoid::RawValue(BigDecimal('1'))).to_a).to eq [band6, band7]
      end

      it 'does not match objects without raw value' do
        expect(Band.where(name: BigDecimal('1')).to_a).to eq []
      end
    end

    context 'Range field' do
      it 'matches objects with raw value' do
        expect(Band.where(decibels: Mongoid::RawValue(BigDecimal('90'))).to_a).to eq [band7]
      end

      it 'matches objects without raw value because BigDecimal cannot be evolved to Range' do
        expect(Band.where(decibels: BigDecimal('90')).to_a).to eq [band7]
      end
    end

    context 'Date field' do
      it 'does not match objects with raw value' do
        expect(Band.where(founded: Mongoid::RawValue(BigDecimal('1577923200'))).to_a).to eq [band7]
      end

      it 'matches objects without raw value because BigDecimal cannot be evolved to Date' do
        expect(Band.where(founded: BigDecimal('1577923200')).to_a).to eq [band7]
      end
    end

    context 'Time field' do
      it 'does not match objects with raw value' do
        expect(Band.where(updated: Mongoid::RawValue(BigDecimal('1578153600'))).to_a).to eq [band7]
      end

      it 'matches objects without raw value because BigDecimal cannot be evolved to Time' do
        expect(Band.where(updated: BigDecimal('1578153600')).to_a).to eq [band7]
      end
    end
  end

  context 'Mongoid::RawValue<Range>' do

    context 'Integer field' do
      it 'raises a BSON error with raw value' do
        expect { Band.where(likes: Mongoid::RawValue(0..2)).to_a }.to raise_error BSON::Error::UnserializableClass
      end

      it 'matches objects without raw value' do
        expect(Band.where(likes: 0..2).to_a).to eq [band1, band2, band3, band4]
      end
    end

    context 'Float field' do
      it 'raises a BSON error with raw value' do
        expect { Band.where(rating: Mongoid::RawValue(1..3)).to_a }.to raise_error BSON::Error::UnserializableClass
      end

      it 'matches objects without raw value' do
        expect(Band.where(rating: 1..3).to_a).to eq [band2, band3]
      end
    end

    context 'BigDecimal field' do
      it 'raises a BSON error with raw value' do
        expect { Band.where(sales: Mongoid::RawValue(100..300)).to_a }.to raise_error BSON::Error::UnserializableClass
      end

      it 'matches objects without raw value' do
        expect(Band.where(sales: 100..300).to_a).to eq [band2, band3]
      end
    end

    context 'String field' do
      it 'raises a BSON error with raw value' do
        expect { Band.where(name: Mongoid::RawValue(1..3)).to_a }.to raise_error BSON::Error::UnserializableClass
      end

      it 'matches objects without raw value' do
        expect(Band.where(name: 1..3).to_a).to eq [band1, band2, band3, band4]
      end
    end

    context 'Range field' do
      it 'raises a BSON error with raw value' do
        expect { Band.where(decibels: Mongoid::RawValue(30..90)).to_a }.to raise_error BSON::Error::UnserializableClass
      end

      it 'matches objects without raw value because Range is evolved into a gte/lte query range' do
        expect(Band.where(decibels: 30..90).to_a).to eq [band7]
        expect(Band.where(decibels: 20..100).to_a).to eq [band7]
      end
    end

    context 'Date field' do
      it 'raises a BSON error with raw value' do
        expect { Band.where(founded: Mongoid::RawValue(1577923199..1577923201)).to_a }.to raise_error BSON::Error::UnserializableClass
      end

      it 'matches objects without raw value' do
        expect(Band.where(founded: 1577923199..1577923201).to_a).to eq [band1, band2, band3, band4]
      end
    end

    context 'Time field' do
      it 'raises a BSON error with raw value' do
        expect { Band.where(founded: Mongoid::RawValue(1578153599..1578153600)).to_a }.to raise_error BSON::Error::UnserializableClass
      end

      it 'matches objects without raw value' do
        expect(Band.where(updated: 1578153599..1578153600).to_a).to eq [band4, band5]
      end
    end
  end

  context 'Mongoid::RawValue<Time>' do
    let!(:band7) do
      id = BSON::ObjectId.new
      Band.collection.insert_one(_id: id, name: Time.at(1), likes: Time.at(1), rating: Time.at(3.1), sales: Time.at(310), decibels: Time.at(90))
      Band.find(id)
    end

    context 'Integer field' do
      it 'does not match objects with raw value' do
        expect(Band.where(likes: Mongoid::RawValue(Time.at(1))).to_a).to eq [band7]
      end

      it 'matches objects without raw value' do
        expect(Band.where(likes: Time.at(1)).to_a).to eq [band2, band3]
      end
    end

    context 'Float field' do
      it 'matches objects with raw value' do
        expect(Band.where(rating: Mongoid::RawValue(Time.at(3.1))).to_a).to eq [band7]
      end

      it 'matches objects without raw value' do
        expect(Band.where(rating: Time.at(3.1)).to_a).to eq [band4, band5]
      end
    end

    context 'BigDecimal field' do
      it 'matches objects with raw value' do
        expect(Band.where(sales: Mongoid::RawValue(Time.at(310))).to_a).to eq [band7]
      end

      it 'matches objects without raw value because Time does not evolve into BigDecimal' do
        expect(Band.where(sales: Time.at(310)).to_a).to eq [band7]
      end
    end

    context 'String field' do
      it 'matches objects with raw value' do
        expect(Band.where(name: Mongoid::RawValue(Time.at(1))).to_a).to eq [band7]
      end

      it 'does not match objects without raw value' do
        expect(Band.where(name: Time.at(1)).to_a).to eq []
      end
    end

    context 'Range field' do
      it 'matches objects with raw value' do
        expect(Band.where(decibels: Mongoid::RawValue(Time.at(90))).to_a).to eq [band7]
      end

      it 'matches objects without raw value because BigDecimal cannot be evolved to Range' do
        expect(Band.where(decibels: Time.at(90)).to_a).to eq [band7]
      end
    end

    context 'Date field' do
      it 'matches objects with raw value when exact' do
        expect(Band.where(founded: Mongoid::RawValue(Time.at(1577923200))).to_a).to eq [band3, band4]
      end

      it 'does not match objects with raw value when non-exact' do
        expect(Band.where(founded: Mongoid::RawValue(Time.at(1577923199))).to_a).to eq []
      end

      it 'matches objects without raw value when exact' do
        expect(Band.where(founded: Time.at(1577923200).utc).to_a).to eq [band3, band4]
      end

      it 'matches objects without raw value when 1 second before midnight' do
        expect(Band.where(founded: Time.at(1577923199).utc).to_a).to eq [band1, band2]
      end

      it 'matches objects without raw value when 1 second after midnight' do
        expect(Band.where(founded: Time.at(1577923201).utc).to_a).to eq [band3, band4]
      end
    end

    context 'Time field' do
      it 'matches objects with raw value' do
        expect(Band.where(updated: Mongoid::RawValue(Time.at(1578153600))).to_a).to eq [band4, band5]
      end

      it 'matches objects without raw value' do
        expect(Band.where(updated: Time.at(1578153600)).to_a).to eq [band4, band5]
      end
    end
  end

  context 'Mongoid::RawValue<Date>' do
    let!(:band7) { Band.create!(updated: Time.at(1577923200)) }

    context 'Date field' do
      it 'matches objects with raw value' do
        expect(Band.where(founded: Mongoid::RawValue(Time.at(1577923200).utc.to_date)).to_a).to eq [band3, band4]
      end

      it 'matches objects without raw value when non-exact' do
        expect(Band.where(founded: Time.at(1577923200).utc.to_date).to_a).to eq [band3, band4]
      end
    end

    context 'Time field' do
      it 'matches objects with raw value' do
        expect(Band.where(updated: Mongoid::RawValue(Time.at(1577923200).utc.to_date)).to_a).to eq [band7]
      end

      it 'matches objects without raw value' do
        Time.use_zone('UTC') do
          expect(Band.where(updated: Time.at(1577923200).utc.to_date).to_a).to eq [band7]
        end
      end

      it 'does not matches objects without raw value when in other timezone' do
        Time.use_zone('Asia/Tokyo') do
          expect(Band.where(updated: Time.at(1577923200).utc.to_date).to_a).to eq []
        end
      end
    end
  end
end
