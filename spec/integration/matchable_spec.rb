# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'Matcher' do
  context 'when attribute is a scalar' do
    describe 'exact match' do

      let!(:slave) do
        Slave.create!(address_numbers: [
          AddressNumber.new(number: '123'),
          AddressNumber.new(number: '456'),
        ])
      end

      describe 'MongoDB query' do
        let(:found_slave) do
          Slave.where('address_numbers.number' => '123').first
        end

        it 'finds' do
          expect(found_slave).to eq(slave)
        end
      end

      describe 'Mongoid matcher' do
        let(:found_number) do
          slave.address_numbers.where(number: '123').first
        end

        it 'finds' do
          expect(found_number).to be slave.address_numbers.first
        end
      end
    end

    describe 'regexp match on string' do

      let!(:slave) do
        Slave.create!(address_numbers: [
          AddressNumber.new(number: '123'),
          AddressNumber.new(number: '456'),
        ])
      end

      describe 'MongoDB query' do
        let(:found_slave) do
          Slave.where('address_numbers.number' => /123/).first
        end

        it 'finds' do
          expect(found_slave).to eq(slave)
        end
      end

      describe 'Mongoid matcher' do
        let(:found_number) do
          slave.address_numbers.where(number: /123/).first
        end

        it 'finds' do
          expect(found_number).to be slave.address_numbers.first
        end
      end
    end

    describe 'range match on number' do

      let!(:circuit) do
        Circuit.create!(buses: [
          Bus.new(number: '10'),
          Bus.new(number: '30'),
        ])
      end

      describe 'MongoDB query' do
        let(:found_circuit) do
          Circuit.where('buses.number' => 10..15).first
        end

        it 'finds' do
          expect(found_circuit).to eq(circuit)
        end
      end

      describe 'Mongoid matcher' do
        let(:found_bus) do
          circuit.buses.where(number: 10..15).first
        end

        it 'finds' do
          expect(found_bus).to be circuit.buses.first
        end
      end
    end

    shared_examples_for 'a field operator' do |_operator|
      shared_examples_for 'behaves as expected' do
        context 'matching condition' do
          it 'finds' do
            expect(actual_object_matching_condition).to be expected_object_matching_condition
          end
        end

        context 'not matching condition' do
          it 'does not find' do
            expect(actual_object_not_matching_condition).to be nil
          end
        end
      end

      context 'as string' do
        let(:operator) { _operator.to_s }

        it_behaves_like 'behaves as expected'
      end

      context 'as symbol' do
        let(:operator) { _operator.to_sym }

        it_behaves_like 'behaves as expected'
      end
    end

    describe '$eq' do

      let!(:circuit) do
        Circuit.new(buses: [
          Bus.new(number: '10'),
          Bus.new(number: '30'),
        ])
      end

      let(:actual_object_matching_condition) do
        circuit.buses.where(number: {operator => 10}).first
      end

      let(:expected_object_matching_condition) do
        circuit.buses.first
      end

      let(:actual_object_not_matching_condition) do
        circuit.buses.where(number: {operator => 20}).first
      end

      it_behaves_like 'a field operator', '$eq'
    end

    describe '$gt' do

      let!(:circuit) do
        Circuit.new(buses: [
          Bus.new(number: '10'),
          Bus.new(number: '30'),
        ])
      end

      let(:actual_object_matching_condition) do
        circuit.buses.where(number: {operator => 15}).first
      end

      let(:expected_object_matching_condition) do
        circuit.buses.last
      end

      let(:actual_object_not_matching_condition) do
        # Intentionally equal to the largest bus number
        circuit.buses.where(number: {operator => 30}).first
      end

      it_behaves_like 'a field operator', '$gt'
    end

    describe '$gte' do

      let!(:circuit) do
        Circuit.new(buses: [
          Bus.new(number: '10'),
          Bus.new(number: '30'),
        ])
      end

      let(:actual_object_matching_condition) do
        # Intentionally equal to the largest bus number
        circuit.buses.where(number: {operator => 30}).first
      end

      let(:expected_object_matching_condition) do
        circuit.buses.last
      end

      let(:actual_object_not_matching_condition) do
        circuit.buses.where(number: {operator => 31}).first
      end

      it_behaves_like 'a field operator', '$gte'
    end

    describe '$lt' do

      let!(:circuit) do
        Circuit.new(buses: [
          Bus.new(number: '10'),
          Bus.new(number: '30'),
        ])
      end

      let(:actual_object_matching_condition) do
        circuit.buses.where(number: {operator => 15}).first
      end

      let(:expected_object_matching_condition) do
        circuit.buses.first
      end

      let(:actual_object_not_matching_condition) do
        # Intentionally equal to the smallest bus number
        circuit.buses.where(number: {operator => 10}).first
      end

      it_behaves_like 'a field operator', '$lt'
    end

    describe '$lte' do

      let!(:circuit) do
        Circuit.new(buses: [
          Bus.new(number: '10'),
          Bus.new(number: '30'),
        ])
      end

      let(:actual_object_matching_condition) do
        # Intentionally equal to the smallest bus number
        circuit.buses.where(number: {operator => 10}).first
      end

      let(:expected_object_matching_condition) do
        circuit.buses.first
      end

      let(:actual_object_not_matching_condition) do
        circuit.buses.where(number: {operator => 9}).first
      end

      it_behaves_like 'a field operator', '$lte'
    end
  end

  context 'when attribute is an array' do
    describe 'exact match of array element' do

      let!(:band) do
        Band.create!(records: [
          Record.new(producers: ['Ferguson', 'Fallon']),
        ])
      end

      describe 'MongoDB query' do
        let(:found_band) do
          Band.where('records.producers' => 'Ferguson').first
        end

        it 'finds' do
          expect(found_band).to eq(band)
        end
      end

      describe 'Mongoid matcher' do
        let(:found_record) do
          band.records.where(producers: 'Ferguson').first
        end

        it 'finds' do
          expect(found_record).to be band.records.first
        end
      end
    end

    describe 'regexp match on array element' do

      let!(:band) do
        Band.create!(records: [
          Record.new(producers: ['Ferguson', 'Fallon']),
        ])
      end

      describe 'MongoDB query' do
        let(:found_band) do
          Band.where('records.producers' => /Ferg/).first
        end

        it 'finds' do
          expect(found_band).to eq(band)
        end
      end

      describe 'Mongoid matcher' do
        let(:found_record) do
          band.records.where(producers: /Ferg/).first
        end

        it 'finds' do
          expect(found_record).to be band.records.first
        end
      end
    end

    describe 'range match on array element' do

      let!(:band) do
        Band.create!(records: [
          Record.new(producers: [123, 456]),
        ])
      end

      describe 'MongoDB query' do
        let(:found_band) do
          Band.where('records.producers' => 100..200).first
        end

        it 'finds' do
          expect(found_band).to eq(band)
        end
      end

      describe 'Mongoid matcher' do
        let(:found_record) do
          band.records.where(producers: 100..200).first
        end

        it 'finds' do
          expect(found_record).to be band.records.first
        end
      end
    end
  end
end
