# frozen_string_literal: true

require 'spec_helper'
require_relative '../../mongoid/association/referenced/has_and_belongs_to_many_models'
require_relative '../../mongoid/association/referenced/has_many_models'
require_relative '../../mongoid/association/referenced/has_one_models'

describe 'association :scope option' do

  context 'has_many and belongs_to' do
    let!(:trainer1) { HmmTrainer.create!(name: 'Dave') }
    let!(:trainer2) { HmmTrainer.create!(name: 'Ash') }
    let!(:animal1) { HmmAnimal.create!(taxonomy: 'reptile', trainer: trainer1) }
    let!(:animal2) { HmmAnimal.create!(taxonomy: 'bird', trainer: trainer1) }
    let!(:animal3) { HmmAnimal.create!(taxonomy: 'mammal', trainer: trainer2) }

    it 'initially associates the documents in-memory' do
      expect(trainer1.animals).to eq [animal1, animal2]
      expect(trainer2.animals).to eq [animal3]
      expect(animal1.trainer).to eq trainer1
      expect(animal2.trainer).to eq trainer1
      expect(animal3.trainer).to eq trainer2
    end

    it 'loads correct documents when queried' do
      expect(trainer1.reload.animals).to eq [animal1]
      expect(trainer2.reload.animals).to eq []
      expect(animal1.reload.trainer).to eq trainer1
      expect(animal2.reload.trainer).to eq trainer1
      expect(animal3.reload.trainer).to be_nil
    end

    it 'eager loads correct documents' do
      expect(HmmTrainer.includes(:animals).find(trainer1._id).animals).to eq [animal1]
      expect(HmmTrainer.includes(:animals).find(trainer2._id).animals).to eq []
      expect(HmmAnimal.includes(:trainer).find(animal1._id).trainer).to eq trainer1
      expect(HmmAnimal.includes(:trainer).find(animal2._id).trainer).to eq trainer1
      expect(HmmAnimal.includes(:trainer).find(animal3._id).trainer).to be_nil
    end
  end

  context 'has_one and belongs_to' do
    let!(:trainer1) { HomTrainer.create!(name: 'Dave') }
    let!(:trainer2) { HomTrainer.create!(name: 'Ash') }
    let!(:animal1) { HomAnimal.create!(taxonomy: 'reptile', trainer: trainer1) }
    let!(:animal2) { HomAnimal.create!(taxonomy: 'bird', trainer: trainer1) }
    let!(:animal3) { HomAnimal.create!(taxonomy: 'mammal', trainer: trainer2) }

    it 'initially associates the documents in-memory' do
      expect(trainer1.animal).to eq animal2
      expect(trainer2.animal).to eq animal3
      expect(animal1.trainer).to be_nil
      expect(animal2.trainer).to eq trainer1
      expect(animal3.trainer).to eq trainer2
    end

    it 'loads correct documents when queried' do
      expect(trainer1.reload.animal).to eq animal1
      expect(trainer2.reload.animal).to be_nil
      expect(animal1.reload.trainer).to eq trainer1
      expect(animal2.reload.trainer).to eq trainer1
      expect(animal3.reload.trainer).to be_nil
    end

    it 'eager loads correct documents' do
      expect(HomTrainer.includes(:animal).find(trainer1._id).animal).to eq animal1
      expect(HomTrainer.includes(:animal).find(trainer2._id).animal).to be_nil
      expect(HomAnimal.includes(:trainer).find(animal1._id).trainer).to eq trainer1
      expect(HomAnimal.includes(:trainer).find(animal2._id).trainer).to eq trainer1
      expect(HomAnimal.includes(:trainer).find(animal3._id).trainer).to be_nil
    end
  end

  context 'has_and_belongs_to_many' do
    let!(:trainer1) { HabtmmTrainer.create!(name: 'Dave') }
    let!(:trainer2) { HabtmmTrainer.create!(name: 'Ash') }
    let!(:animal1) { HabtmmAnimal.create!(taxonomy: 'reptile', trainers: [trainer1, trainer2]) }
    let!(:animal2) { HabtmmAnimal.create!(taxonomy: 'bird', trainers: [trainer1, trainer2]) }

    it 'initially associates the documents in-memory' do
      expect(trainer1.animals).to eq [animal1]
      expect(trainer2.animals).to eq [animal1]
      expect(animal1.trainers).to eq [trainer1, trainer2]
      expect(animal2.trainers).to eq [trainer1, trainer2]
    end

    it 'loads correct documents when queried' do
      expect(trainer1.reload.animals).to eq [animal1]
      expect(trainer2.reload.animals).to eq [animal1]
      expect(animal1.reload.trainers).to eq [trainer1]
      expect(animal2.reload.trainers).to eq [trainer1]
    end

    it 'eager loads correct documents' do
      expect(HabtmmTrainer.includes(:animals).find(trainer1._id).animals).to eq [animal1]
      expect(HabtmmTrainer.includes(:animals).find(trainer2._id).animals).to eq [animal1]
      expect(HabtmmAnimal.includes(:trainers).find(animal1._id).trainers).to eq [trainer1]
      expect(HabtmmAnimal.includes(:trainers).find(animal2._id).trainers).to eq [trainer1]
    end
  end
end
