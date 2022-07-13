# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Findable do

  describe ".distinct" do

    before do
      Band.create!(name: "Tool")
      Band.create!(name: "Photek")
    end

    it "returns the distinct values for the field" do
      expect(Band.distinct(:name).sort).to eq([ "Photek", "Tool" ])
    end
  end

  describe ".each" do

    let!(:band) do
      Band.create!
    end

    it "iterates through all documents" do
      Band.each do |band|
        expect(band).to be_a(Band)
      end
    end
  end

  describe ".each_with_index" do

    let!(:band) do
      Band.create!
    end

    it "iterates through all documents" do
      Band.each_with_index do |band, index|
        expect(index).to eq(0)
      end
    end
  end

  describe ".find_one_and_update" do

    let!(:person) do
      Person.create!(title: "Senior")
    end

    it "returns the document" do
      expect(Person.find_one_and_update(title: "Junior")).to eq(person)
    end
  end

  describe ".find_by" do

    context "when collection is a embeds_many" do

      let(:person) do
        Person.create!(title: "sir")
      end

      let!(:message) do
        person.messages.create!(body: 'foo')
      end

      context "when the document is found" do

        it "returns the document" do
          expect(person.messages.find_by(body: 'foo')).to eq(message)
        end
      end

      context "when the document is not found" do

        context "when raising a not found error" do

          let!(:raise_option) { Mongoid.raise_not_found_error }

          before { Mongoid.raise_not_found_error = true }

          after { Mongoid.raise_not_found_error = raise_option }

          it "raises an error" do
            expect {
              person.messages.find_by(body: 'bar')
            }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document not found for class Message with attributes/)
          end
        end

        context "when raising no error" do

          let!(:raise_option) { Mongoid.raise_not_found_error }

          before { Mongoid.raise_not_found_error = false }

          after { Mongoid.raise_not_found_error = raise_option }

          it "returns nil" do
            expect(person.messages.find_by(body: 'bar')).to be_nil
          end
        end
      end
    end

    context "when the document is found" do

      let!(:person) do
        Person.create!(title: "sir")
      end

      context "when no block is provided" do

        it "returns the document" do
          expect(Person.find_by(title: "sir")).to eq(person)
        end
      end

      context "when a block is provided" do

        let(:result) do
          Person.find_by(title: "sir") do |peep|
            peep.age = 50
          end
        end

        it "yields the returned document" do
          expect(result.age).to eq(50)
        end
      end
    end

    context "when the document is not found" do

      context "when raising a not found error" do

        let!(:raise_option) { Mongoid.raise_not_found_error }

        before { Mongoid.raise_not_found_error = true }

        after { Mongoid.raise_not_found_error = raise_option }

        it "raises an error" do
          expect {
            Person.find_by(ssn: "333-22-1111")
          }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document not found for class Person with attributes/)
        end
      end

      context "when raising no error" do

        let!(:raise_option) { Mongoid.raise_not_found_error }

        before { Mongoid.raise_not_found_error = false }

        after { Mongoid.raise_not_found_error = raise_option }

        context "when no block is provided" do

          it "returns nil" do
            expect(Person.find_by(ssn: "333-22-1111")).to be_nil
          end
        end

        context "when a block is provided" do

          let(:result) do
            Person.find_by(ssn: "333-22-1111") do |peep|
              peep.age = 50
            end
          end

          it "returns nil" do
            expect(result).to be_nil
          end
        end
      end
    end
  end

  describe "find_by!" do

    context "when the document is found" do

      let!(:person) do
        Person.create!(title: "sir")
      end

      context "when no block is provided" do

        it "returns the document" do
          expect(Person.find_by!(title: "sir")).to eq(person)
        end
      end

      context "when a block is provided" do

        let(:result) do
          Person.find_by!(title: "sir") do |peep|
            peep.age = 50
          end
        end

        it "yields the returned document" do
          expect(result.age).to eq(50)
        end
      end
    end

    context "when the document is not found" do

      it "raises an error" do
        expect {
          Person.find_by!(ssn: "333-22-1111")
        }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document not found for class Person with attributes/)
      end
    end
  end

  [ :first, :one ].each do |method|

    describe "##{method}" do

      let!(:person) do
        Person.create!
      end

      it "returns the first matching document" do
        expect(Person.send(method)).to eq(person)
      end

      it "passes the limit through" do
        expect(Person.last(1)).to eq([ person ])
      end
    end
  end

  describe "#last" do
    let!(:person) do
      Person.create!
    end

    it "returns the first matching document" do
      expect(Person.last).to eq(person)
    end

    it "passes the limit through" do
      expect(Person.last(1)).to eq([ person ])
    end
  end

  describe ".first_or_create" do

    context "when the document is found" do

      let!(:person) do
        Person.create!
      end

      it "returns the document" do
        expect(Person.first_or_create).to eq(person)
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create!
        end

        let(:from_db) do
          Game.first_or_create(person: person)
        end

        it "returns the new document" do
          expect(from_db.person).to eq(person)
        end
      end

      context "when not providing a block" do

        let!(:person) do
          Person.first_or_create(title: "Senorita")
        end

        it "creates a persisted document" do
          expect(person).to be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.first_or_create(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a persisted document" do
          expect(person).to be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end

        it "calls the block" do
          expect(person.pets).to be true
        end
      end
    end
  end

  describe ".first_or_initialize" do

    context "when the document is found" do

      let!(:person) do
        Person.create!
      end

      it "returns the document" do
        expect(Person.first_or_create).to eq(person)
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create!
        end

        let(:found) do
          Game.first_or_initialize(person: person)
        end

        it "returns the new document" do
          expect(found.person).to eq(person)
        end

        it "does not save the document" do
          expect(found).to_not be_persisted
        end
      end

      context "when not providing a block" do

        before do
          Person.delete_all
        end

        let!(:person) do
          Person.first_or_initialize(title: "esquire")
        end

        it "creates a non persisted document" do
          expect(person).to_not be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("esquire")
        end
      end

      context "when providing a block" do

        let!(:person) do
          Person.first_or_initialize(title: "Senorita") do |person|
            person.pets = true
          end
        end

        it "creates a new document" do
          expect(person).to_not be_persisted
        end

        it "sets the attributes" do
          expect(person.title).to eq("Senorita")
        end

        it "calls the block" do
          expect(person.pets).to be true
        end
      end
    end
  end

  describe ".none" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode", likes: 3)
    end

    context "when not chaining any criteria" do

      it "returns no records" do
        expect(Band.none).to be_empty
      end

      it "has an empty count" do
        expect(Band.none.count).to eq(0)
      end

      it "returns nil for first" do
        expect(Band.none.first).to be_nil
      end

      it "returns nil for last" do
        expect(Band.none.last).to be_nil
      end

      it "returns zero for length" do
        expect(Band.none.length).to eq(0)
      end

      it "returns zero for size" do
        expect(Band.none.size).to eq(0)
      end
    end

    context "when chaining criteria after the none" do

      let(:criteria) do
        Band.none.where(name: "Depeche Mode")
      end

      it "returns no records" do
        expect(criteria).to be_empty
      end

      it "has an empty count" do
        expect(criteria.count).to eq(0)
      end

      it "returns nil for first" do
        expect(criteria.first).to be_nil
      end

      it "returns nil for last" do
        expect(criteria.last).to be_nil
      end

      it "returns zero for length" do
        expect(criteria.length).to eq(0)
      end

      it "returns zero for size" do
        expect(criteria.size).to eq(0)
      end
    end
  end

  describe ".pluck" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode", likes: 3)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 3)
    end

    let!(:photek) do
      Band.create!(name: "Photek", likes: 1)
    end

    context "when field values exist" do

      let(:plucked) do
        Band.pluck(:name)
      end

      it "returns the field values" do
        expect(plucked).to eq([ "Depeche Mode", "Tool", "Photek" ])
      end
    end

    context "when field values do not exist" do

      let(:plucked) do
        Band.pluck(:follows)
      end

      it "returns an array with nil values" do
        expect(plucked).to eq([nil, nil, nil])
      end
    end
  end

  describe '.count' do
    context 'when the collection is not empty' do
      before do
        Band.create!(name: "Tool")
        Band.create!(name: "Photek")
      end

      it 'returns the currect count' do
        expect(Band.count).to eq(2)
      end
    end
  end

  describe '.estimated_count' do
    context 'when the collection is not empty' do
      before do
        Band.create!(name: "Tool")
        Band.create!(name: "Photek")
      end

      it 'returns the correct count' do
        expect(Band.estimated_count).to eq(2)
      end
    end

    context 'when the collection is empty' do
      it 'returns the correct count' do
        expect(Band.estimated_count).to eq(0)
      end
    end
  end

  Mongoid::Criteria::Queryable::Selectable.forwardables.each do |method|

    describe "##{method}" do

      it "forwards the #{method} to the criteria" do
        expect(Band).to respond_to(method)
      end
    end
  end

  context 'when Mongoid is configured to use activesupport time zone' do
    config_override :use_utc, false
    config_override :use_activesupport_time_zone, true

    before do
      Time.zone = "Asia/Kolkata"
    end

    let!(:time) do
      Time.zone.now.tap do |t|
        User.create!(last_login: t, name: 'Tom')
      end
    end

    context 'when distinct does not demongoize' do
      config_override :legacy_pluck_distinct, true

      let(:distinct) do
        User.distinct(:last_login).first
      end

      it 'uses activesupport time zone' do
        distinct.should be_a(ActiveSupport::TimeWithZone)
        expect(distinct.to_s).to eql(time.in_time_zone('Asia/Kolkata').to_s)
      end
    end

    context 'when distinct demongoizes' do
      config_override :legacy_pluck_distinct, false

      let(:distinct) do
        User.distinct(:last_login).first
      end

      it 'uses activesupport time zone' do
        distinct.should be_a(DateTime)
        # Time and DateTime have different stringifications:
        # 2022-03-16T21:12:32+00:00
        # 2022-03-16 21:12:32 UTC
        expect(distinct.to_s).to eql(time.in_time_zone('Asia/Kolkata').to_datetime.to_s)
      end
    end

    it 'loads other fields accurately' do
      expect(User.distinct(:name)).to match_array(['Tom'])
    end
  end

  context 'when Mongoid is not configured to use activesupport time zone' do
    config_override :use_utc, true
    config_override :use_activesupport_time_zone, false

    let!(:time) do
      Time.now.tap do |t|
        User.create!(last_login: t, name: 'Tom')
      end
    end

    context 'when distinct does not demongoize' do
      config_override :legacy_pluck_distinct, true

      let(:distinct) do
        User.distinct(:last_login).first
      end

      it 'uses utc' do
        distinct.should be_a(Time)
        expect(distinct.to_s).to eql(time.utc.to_s)
      end
    end

    context 'when distinct demongoizes' do
      config_override :legacy_pluck_distinct, false

      let(:distinct) do
        User.distinct(:last_login).first
      end

      it 'uses utc' do
        distinct.should be_a(DateTime)
        # Time and DateTime have different stringifications:
        # 2022-03-16T21:12:32+00:00
        # 2022-03-16 21:12:32 UTC
        expect(distinct.to_s).to eql(time.utc.to_datetime.to_s)
      end
    end

    it 'loads other fields accurately' do
      expect(User.distinct(:name)).to match_array(['Tom'])
    end
  end
end
