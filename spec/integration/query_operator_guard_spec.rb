# frozen_string_literal: true

require 'spec_helper'

describe 'query operator injection guard' do
  let(:js) { 'this.name == "admin"' }

  let(:nested_function) do
    { '$expr' => { '$function' => { 'body' => 'function() { return true; }', 'args' => [], 'lang' => 'js' } } }
  end

  let(:band) { Band.create!(name: 'Depeche Mode') }

  context 'with default configuration' do
    it 'rejects unsafe operators without any opt-out' do
      expect(Mongoid.allow_unsafe_query_operators).to be false
    end

    context 'when querying with where' do
      it 'rejects a top-level $where' do
        expect { Band.where('$where' => js).first }.to raise_error(Mongoid::Errors::InvalidQuery)
      end

      it 'rejects a $function nested in $expr' do
        expect { Band.where(nested_function).first }.to raise_error(Mongoid::Errors::InvalidQuery)
      end

      it 'permits an ordinary query' do
        expect(Band.where(name: band.name).first).to eq(band)
      end
    end

    context 'when querying with find_by' do
      it 'rejects a top-level $where' do
        expect { Band.find_by('$where' => js) }.to raise_error(Mongoid::Errors::InvalidQuery)
      end

      it 'rejects a $function nested in $expr' do
        expect { Band.find_by(nested_function) }.to raise_error(Mongoid::Errors::InvalidQuery)
      end
    end

    context 'when querying with find_or_create_by' do
      it 'rejects a top-level $where' do
        expect { Band.find_or_create_by('$where' => js) }.to raise_error(Mongoid::Errors::InvalidQuery)
      end
    end

    context 'when querying with find_or_initialize_by' do
      it 'rejects a top-level $where' do
        expect { Band.find_or_initialize_by('$where' => js) }.to raise_error(Mongoid::Errors::InvalidQuery)
      end
    end

    context 'when querying an association with find_or_create_by' do
      it 'rejects a top-level $where' do
        expect do
          band.records.find_or_create_by('$where' => js)
        end.to raise_error(Mongoid::Errors::InvalidQuery)
      end
    end

    context 'when querying with a logical operator' do
      it 'rejects a $where smuggled through or' do
        expect { Band.or('$where' => js).first }.to raise_error(Mongoid::Errors::InvalidQuery)
      end

      it 'rejects a $where smuggled through any_of' do
        expect { Band.any_of('$where' => js).first }.to raise_error(Mongoid::Errors::InvalidQuery)
      end
    end
  end

  context 'when allow_unsafe_query_operators is true' do
    config_override :allow_unsafe_query_operators, true

    it 'permits a top-level $where' do
      expect(Band.where('$where' => "this.name == '#{band.name}'").first).to eq(band)
    end

    it 'permits a $function nested in $expr' do
      expect { Band.where(nested_function).first }.not_to raise_error
    end

    it 'permits a $where smuggled through or' do
      expect { Band.or('$where' => js).first }.not_to raise_error
    end
  end
end
