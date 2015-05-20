require "spec_helper"

describe Mongoid::Findable do

  describe ".distinct" do

    before do
      Band.create(name: "Tool")
      Band.create(name: "Photek")
    end

    it "returns the distinct values for the field" do
      expect(Band.distinct(:name)).to eq([ "Tool", "Photek" ])
    end
  end

  describe ".each" do

    let!(:band) do
      Band.create
    end

    it "iterates through all documents" do
      Band.each do |band|
        expect(band).to be_a(Band)
      end
    end
  end

  describe ".each_with_index" do

    let!(:band) do
      Band.create
    end

    it "iterates through all documents" do
      Band.each_with_index do |band, index|
        expect(index).to eq(0)
      end
    end
  end

  describe ".find_one_and_update" do

    let!(:person) do
      Person.create(title: "Senior")
    end

    it "returns the document" do
      expect(Person.find_one_and_update(title: "Junior")).to eq(person)
    end
  end

  describe ".find_by" do

    context "when collection is a embeds_many" do

      let(:person) do
        Person.create(title: "sir")
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
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
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
        Person.create(title: "sir")
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
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
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
        Person.create(title: "sir")
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
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  [ :first, :one ].each do |method|

    describe "##{method}" do

      let!(:person) do
        Person.create
      end

      it "returns the first matching document" do
        expect(Person.send(method)).to eq(person)
      end
    end
  end

  describe ".first_or_create" do

    context "when the document is found" do

      let!(:person) do
        Person.create
      end

      it "returns the document" do
        expect(Person.first_or_create).to eq(person)
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create
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
        Person.create
      end

      it "returns the document" do
        expect(Person.first_or_create).to eq(person)
      end
    end

    context "when the document is not found" do

      context "when providing a document" do

        let!(:person) do
          Person.create
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
      Band.create(name: "Depeche Mode", likes: 3)
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
      Band.create(name: "Depeche Mode", likes: 3)
    end

    let!(:tool) do
      Band.create(name: "Tool", likes: 3)
    end

    let!(:photek) do
      Band.create(name: "Photek", likes: 1)
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

      it "returns a array with nil values" do
        expect(plucked).to eq([nil, nil, nil])
      end
    end
  end

  Origin::Selectable.forwardables.each do |method|

    describe "##{method}" do

      it "forwards the #{method} to the criteria" do
        expect(Band).to respond_to(method)
      end
    end
  end
end
