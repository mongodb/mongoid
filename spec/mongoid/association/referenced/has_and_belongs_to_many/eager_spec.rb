# frozen_string_literal: true

require "spec_helper"
require_relative '../has_and_belongs_to_many_models'

describe Mongoid::Association::Referenced::HasAndBelongsToMany::Eager do

  describe ".keys_from_docs" do

    let(:docs) do
      Person.all.to_a
    end

    let!(:person) do
      Person.create!(houses: [house])
    end

    let!(:house) do
      House.create!
    end

    let(:association) do
      Person.reflect_on_association(:houses)
    end

    let(:eager) do
      described_class.new([association], docs).tap do |b|
        b.send(:shift_association)
      end
    end

    it "aggregates by the foreign key" do
      expect(eager.send(:keys_from_docs)).to eq([house.id])
    end
  end

  describe ".includes" do

    let(:person) do
      Person.create!
    end

    before do
      Person.create!(houses: 3.times.map { House.create! })
    end

    context "when including the has_and_belongs_to_many association" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      it "queries twice" do
        expect_query(2) do
          Person.asc(:_id).includes(:houses).each do |person|
            expect(person.houses).to_not be_nil

            expect(person.houses.length).to be(3)
          end
        end
      end

      it "has all items" do
        Person.asc(:_id).includes(:houses).each do |person|
          expect(person.ivar(:houses).length).to be(3)
        end
      end
    end

    context "when the association is not polymorphic" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      let(:eager) do
        Person.asc(:_id).includes(:preferences).last
      end

      context "when the eager load has returned documents" do

        let!(:preference) do
          person.preferences.create!(name: "testing")
        end

        before { eager }

        it "puts the documents in the parent document" do
          expect(eager.ivar(:preferences)).to eq([ preference ])
        end

        it "does not query when touching the association" do
          expect_query(0) do
            expect(eager.preferences).to eq([ preference ])
          end
        end

        it "does not query when updating the association" do
          expect_query(0) do
            eager.preferences.first.name = "new pref"
            expect(eager.preferences.first.name).to eq("new pref")
          end
        end
      end

      context "when the eager load has not returned documents" do

        before { eager }

        it "has an empty proxy" do
          expect(eager.preferences).to eq []
        end

        it "does not query when touching the association" do
          expect_query(0) do
            eager.preferences.entries
          end
        end

        it "returns the proxy" do
          expect do
            eager.preferences.create!(name: "testing")
          end.to_not raise_error
        end
      end
    end

    context "when the association has scope" do
      let!(:trainer1) { HabtmmTrainer.create!(name: 'Dave') }
      let!(:trainer2) { HabtmmTrainer.create!(name: 'Ash') }
      let!(:animal1) { HabtmmAnimal.create!(taxonomy: 'reptile', trainers: [trainer1, trainer2]) }
      let!(:animal2) { HabtmmAnimal.create!(taxonomy: 'bird', trainers: [trainer1, trainer2]) }

      context 'when scope set by Symbol' do
        let(:eager) do
          HabtmmAnimal.includes(:trainers).where(_id: animal1._id).first
        end

        it 'eager loads the included docs' do
          expect(eager.trainers._loaded).to eq(trainer1._id => trainer1)
          expect(eager.trainers).to eq [trainer1]
        end
      end

      context 'when scope set by Proc' do
        let(:eager) do
          HabtmmTrainer.includes(:animals).where(_id: trainer1._id).to_a.first
        end

        it 'eager loads the included docs' do
          expect(eager.animals._loaded).to eq(animal1._id => animal1)
          expect(eager.animals).to eq [animal1]
        end
      end
    end

    context "when some related documents no longer exist" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      before do
        # Deleting the first one to meet Builders::Referenced::ManyToMany#query?
        House.collection.find(_id: Person.first.house_ids.first).delete_one
      end

      it "does not accidentally trigger an extra query" do
        expect_query(2) do
          Person.asc(:_id).includes(:houses).each do |person|
            expect(person.houses).to_not be_nil
            expect(person.houses.length).to be(2)
          end
        end
      end
    end

    context "when all the values for the has_and_belongs_to_many association are empty" do
      # Query count assertions require that all queries are sent using the
      # same connection object.
      require_no_multi_shard

      before do
        2.times { |i| HabtmmPerson.create! }
      end

      it "only queries once for the parent documents" do
        found_person = false
        expect_query(1) do
          HabtmmPerson.all.includes(:tickets).each do |person|
            expect(person.tickets).to eq []
            found_person = true
          end
        end
        expect(found_person).to be true
      end
    end
  end
end
