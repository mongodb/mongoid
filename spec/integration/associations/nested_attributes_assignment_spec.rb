# frozen_string_literal: true

require 'spec_helper'

describe 'nested attributes assignment' do
  context 'when creating parent document' do
    context 'when setting deeply nested attributes' do
      context 'embeds_many' do
        let(:truck) { Truck.new }

        it 'persists all documents' do
          truck.attributes = {
            capacity: 1,
            crates_attributes: {
              '0' => {
                volume: 2,
                toys_attributes: {
                  '0' => {
                    name: 'Bear',
                  },
                },
              },
            },
          }

          truck.save!

          _truck = Truck.find(truck.id)
          expect(_truck.capacity).to eq(1)
          expect(_truck.crates.length).to eq(1)
          expect(_truck.crates.first.volume).to eq(2)
          expect(_truck.crates.first.toys.length).to eq(1)
          expect(_truck.crates.first.toys.first.name).to eq('Bear')
        end
      end
    end
  end

  context 'when updating parent document' do
    context 'when setting deeply nested attributes' do
      context 'embeds_many' do
        let(:truck) do
          Truck.create!(
            capacity: 1,
            crates: [Crate.new(
              volume: 2,
              toys: [Toy.new(name: 'Bear')],
            )],
          )
        end

        context 'updating embedded documents' do

          it 'persists all documents' do
            truck.attributes = {
              capacity: 2,
              crates_attributes: {
                '0' => {
                  id: truck.crates.first.id,
                  volume: 3,
                  toys_attributes: {
                    '0' => {
                      id: truck.crates.first.toys.first.id,
                      name: 'Rhino',
                    },
                  },
                },
              },
            }

            truck.save!

            _truck = Truck.find(truck.id)
            expect(_truck.capacity).to eq(2)
            expect(_truck.crates.length).to eq(1)
            expect(_truck.crates.first.volume).to eq(3)
            expect(_truck.crates.first.toys.length).to eq(1)
            expect(_truck.crates.first.toys.first.name).to eq('Rhino')
          end
        end

        context 'adding embedded documents' do

          it 'persists all changes' do
            truck.attributes = {
              capacity: 2,
              crates_attributes: {
                '0' => {
                  volume: 3,
                  toys_attributes: {
                    '0' => {
                      name: 'Rhino',
                    },
                  },
                },
              },
            }

            truck.save!

            _truck = Truck.find(truck.id)
            expect(_truck.capacity).to eq(2)
            expect(_truck.crates.length).to eq(2)
            expect(_truck.crates.first.volume).to eq(2)
            expect(_truck.crates.first.toys.length).to eq(1)
            expect(_truck.crates.first.toys.first.name).to eq('Bear')
            expect(_truck.crates.last.volume).to eq(3)
            expect(_truck.crates.last.toys.length).to eq(1)
            expect(_truck.crates.last.toys.last.name).to eq('Rhino')
          end
        end
      end
    end
  end
end
