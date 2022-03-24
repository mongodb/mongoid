# frozen_string_literal: true

require 'spec_helper'

# Some of these tests duplicate the tests in matcher_operator_spec.rb.
# The tests in this file are retained because they use model instances
# rather than simple hashes as the YAML tests do, hence in theory these tests
# could provide additional coverage.

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

    describe 'range match on scalar' do

      let!(:circuit) do
        Circuit.create!(buses: [
          Bus.new(number: 10),
          Bus.new(number: 30),
        ])
      end

      describe 'MongoDB query' do
        let(:found_circuit) do
          Circuit.where('buses.number' => 10..15).first
        end

        let(:not_found_circuit) do
          Circuit.where('buses.number' => 35..45).first
        end

        it 'finds' do
          expect(found_circuit).to eq(circuit)
        end

        it 'does not find' do
          expect(not_found_circuit).to be nil
        end
      end

      describe 'Mongoid matcher' do
        let(:found_bus) do
          circuit.buses.where(number: 10..15).first
        end

        let(:not_found_bus) do
          circuit.buses.where(number: 12..15).first
        end

        it 'finds' do
          expect(found_bus).to be circuit.buses.first
        end

        it 'does not find' do
          expect(not_found_bus).to be nil
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

    describe '$ne' do

      let!(:circuit) do
        Circuit.new(buses: [
          Bus.new(number: '30'),
        ])
      end

      let(:actual_object_matching_condition) do
        circuit.buses.where(number: {operator => 10}).first
      end

      let(:expected_object_matching_condition) do
        circuit.buses.last
      end

      let(:actual_object_not_matching_condition) do
        circuit.buses.where(number: {operator => 30}).first
      end

      it_behaves_like 'a field operator', '$ne'
    end

    describe '$exists' do

      context 'true value' do
        let!(:circuit) do
          Circuit.new(buses: [
            Bus.new(number: '30'),
          ])
        end

        let(:actual_object_matching_condition) do
          circuit.buses.where(number: {operator => true}).first
        end

        let(:expected_object_matching_condition) do
          circuit.buses.first
        end

        let(:actual_object_not_matching_condition) do
          circuit.buses.where(number: {operator => false}).first
        end

        it_behaves_like 'a field operator', '$exists'
      end

      context 'false value' do
        let!(:circuit) do
          Circuit.new(buses: [
            Bus.new,
          ])
        end

        let(:actual_object_matching_condition) do
          circuit.buses.where(number: {operator => false}).first
        end

        let(:expected_object_matching_condition) do
          circuit.buses.first
        end

        let(:actual_object_not_matching_condition) do
          circuit.buses.where(number: {operator => true}).first
        end

        it_behaves_like 'a field operator', '$exists'
      end
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

    describe '$in' do

      let!(:circuit) do
        Circuit.new(buses: [
          Bus.new(number: '10'),
          Bus.new(number: '30'),
        ])
      end

      let(:actual_object_matching_condition) do
        circuit.buses.where(number: {operator => [10, 20]}).first
      end

      let(:expected_object_matching_condition) do
        circuit.buses.first
      end

      let(:actual_object_not_matching_condition) do
        circuit.buses.where(number: {operator => [5]}).first
      end

      it_behaves_like 'a field operator', '$in'
    end

    describe '$nin' do

      let!(:circuit) do
        Circuit.new(buses: [
          Bus.new(number: '10'),
          Bus.new(number: '30'),
        ])
      end

      let(:actual_object_matching_condition) do
        circuit.buses.where(number: {operator => [5, 10]}).first
      end

      let(:expected_object_matching_condition) do
        circuit.buses.last
      end

      let(:actual_object_not_matching_condition) do
        circuit.buses.where(number: {operator => [10, 30]}).first
      end

      it_behaves_like 'a field operator', '$nin'
    end

    describe '$size' do

      let!(:person) do
        Person.new(addresses: [
          Address.new(locations: [Location.new]),
          Address.new(locations: [Location.new, Location.new]),
        ])
      end

      let(:actual_object_matching_condition) do
        person.addresses.where('locations' => {operator => 2}).first
      end

      let(:expected_object_matching_condition) do
        person.addresses.last
      end

      let(:actual_object_not_matching_condition) do
        person.addresses.where('locations' => {operator => 3}).first
      end

      it_behaves_like 'a field operator', '$size'
    end

    describe '$and' do
      let!(:person) do
        Person.new(addresses: [
          Address.new(locations: [Location.new(name: 'City')]),
          Address.new(locations: [
            # Both criteria are on the same object
            Location.new(name: 'Hall', number: 1),
            Location.new(number: 3),
          ]),
        ])
      end

      let(:actual_object_matching_condition) do
        person.addresses.where(operator => [
          {'locations.name' => 'Hall'},
          {'locations.number' => 1},
        ]).first
      end

      let(:expected_object_matching_condition) do
        person.addresses.last
      end

      let(:actual_object_not_matching_condition) do
        person.addresses.where(operator => [
          {'locations.name' => 'Hall'},
          {'locations.number' => 2},
        ]).first
      end

      it_behaves_like 'a field operator', '$and'

      context 'when branches match different embedded objects' do
        let!(:person) do
          Person.new(addresses: [
            Address.new(locations: [Location.new(name: 'City')]),
            Address.new(locations: [
              Location.new(name: 'Hall'),
              Location.new(number: 1),
            ]),
          ])
        end

        let(:operator) { :$and }

        it 'finds' do
          expect(actual_object_matching_condition).to eq(expected_object_matching_condition)
        end

        context 'when $and is on field level' do
          let(:actual_object_matching_condition) do
            person.addresses.where('locations' => {operator => [
              {'name' => 'Hall'},
              {'number' => 1},
            ]}).first
          end

          it 'is prohibited' do
            expect do
              actual_object_matching_condition
            end.to raise_error(Mongoid::Errors::InvalidFieldOperator)
          end
        end
      end
    end

    describe '$or' do
      let!(:person) do
        Person.new(addresses: [
          Address.new(locations: [Location.new(name: 'City')]),
          Address.new(locations: [
            # Both criteria are on the same object
            Location.new(name: 'Hall', number: 1),
            Location.new(number: 3),
          ]),
        ])
      end

      let(:actual_object_matching_condition) do
        person.addresses.where(operator => [
          {'locations.name' => 'Hall'},
          {'locations.number' => 4},
        ]).first
      end

      let(:expected_object_matching_condition) do
        person.addresses.last
      end

      let(:actual_object_not_matching_condition) do
        person.addresses.where(operator => [
          {'locations.name' => 'Town'},
          {'locations.number' => 4},
        ]).first
      end

      it_behaves_like 'a field operator', '$or'

      context 'when branches match different embedded objects' do
        let(:operator) { :$or }

        context 'when $or is on field level' do
          let(:actual_object_matching_condition) do
            person.addresses.where('locations' => {operator => [
              {'name' => 'Hall'},
              {'number' => 1},
            ]}).first
          end

          it 'is prohibited' do
            expect do
              actual_object_matching_condition
            end.to raise_error(Mongoid::Errors::InvalidFieldOperator)
          end
        end
      end
    end

    describe '$not' do
      let!(:person) do
        Person.new(addresses: [
          Address.new(locations: [
            # Both criteria are on the same object
            Location.new(name: 'Hall', number: 1),
            Location.new(number: 3),
          ]),
        ])
      end

      let(:actual_object_matching_condition) do
        person.addresses.where('locations.name' => {operator =>
          {'$eq' => 'City'},
        }).first
      end

      let(:expected_object_matching_condition) do
        person.addresses.last
      end

      let(:actual_object_not_matching_condition) do
        person.addresses.where('locations.name' => {operator =>
          {'$eq' => 'Hall'},
        }).first
      end

      it_behaves_like 'a field operator', '$not'

      context 'when branches match different embedded objects' do
        let!(:person) do
          Person.new(addresses: [
            Address.new(locations: [Location.new(name: 'City')]),
            Address.new(locations: [
              Location.new(name: 'Hall'),
              Location.new(number: 1),
            ]),
          ])
        end

        let(:operator) { :$not }

        it 'finds' do
          expect(actual_object_matching_condition).to eq(expected_object_matching_condition)
        end

        context 'when $not is on field level' do
          let(:actual_object_matching_condition) do
            person.addresses.where('locations' => {operator => [
              {'name' => 'Hall'},
              {'number' => 1},
            ]}).first
          end

          it 'is prohibited' do
            expect do
              actual_object_matching_condition
            end.to raise_error(Mongoid::Errors::InvalidQuery)
          end
        end
      end
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

      let(:record) do
        Record.new(producers: [123, 456])
      end

      let!(:band) do
        Band.create!(records: [ record ])
      end

      describe 'MongoDB query' do
        let(:found_band) do
          Band.where('records.producers' => 100..200).first
        end

        it 'finds' do
          expect(found_band).to eq(band)
        end

        context 'no match' do

          let!(:band) do
            Band.create!(records: [
              Record.new(producers: [50, 250]),
            ])
          end

          it 'does not find' do
            expect(found_band).to be nil
          end
        end
      end

      describe 'Mongoid matcher' do
        let(:found_record) do
          band.records.where(producers: 100..200).first
        end

        let(:no_record) do
          band.records.where(producers: 199..200).first
        end

        it 'finds correctly' do
          expect(found_record).to eq(record)
        end

        it "correctly does not find" do
          expect(no_record).to eq(nil)
        end
      end
    end
  end

  describe '$elemMatch' do
    context 'hash match against scalar value in embeds_many' do
      context 'string value' do
        let(:band) do
          Band.new(records: [
            Record.new(producers: ['Sunrise']),
          ])
        end

        it 'does not find' do
          band.records.where(producers: {'$elemMatch': {foo: 'bar'}}).first.should be nil
        end

        context 'primitive value query' do

          it 'does not find' do
            lambda do
              band.records.where(producers: {'$elemMatch': 'bar'}).first
            end.should raise_error(Mongoid::Errors::InvalidQuery, /elemMatch requires a Hash operand/)
          end
        end

        context '$not with primitive value' do

          it 'does not find' do
            lambda do
              band.records.where(producers: {'$elemMatch': {'$not': 'bar'}}).first
            end.should raise_error(Mongoid::Errors::InvalidQuery, /\$not argument must be a Hash or a regular expression/)
          end
        end

        context '$not with regexp' do

          it 'finds' do
            band.records.where(producers: {'$elemMatch': {'$not': /bar/}}).count.should == 1
          end
        end

        context '$not with operator' do

          it 'finds' do
            band.records.where(producers: {'$elemMatch': {'$not': {'$eq': 'bar'}}}).count.should == 1
          end
        end
      end

      context 'integer value' do
        let(:band) do
          Band.new(records: [
            Record.new(producers: [42]),
          ])
        end

        it 'does not find' do
          band.records.where(producers: {'$elemMatch': {foo: 'bar'}}).first.should be nil
        end
      end
    end
  end
end
