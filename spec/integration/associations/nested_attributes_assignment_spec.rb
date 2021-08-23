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
          _truck.capacity.should == 1
          _truck.crates.length.should == 1
          _truck.crates.first.volume.should == 2
          _truck.crates.first.toys.length.should == 1
          _truck.crates.first.toys.first.name.should == 'Bear'
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
            _truck.capacity.should == 2
            _truck.crates.length.should == 1
            _truck.crates.first.volume.should == 3
            _truck.crates.first.toys.length.should == 1
            _truck.crates.first.toys.first.name.should == 'Rhino'
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
            _truck.capacity.should == 2
            _truck.crates.length.should == 2
            _truck.crates.first.volume.should == 2
            _truck.crates.first.toys.length.should == 1
            _truck.crates.first.toys.first.name.should == 'Bear'
            _truck.crates.last.volume.should == 3
            _truck.crates.last.toys.length.should == 1
            _truck.crates.last.toys.last.name.should == 'Rhino'
          end
        end
      end
    end
  end
end
