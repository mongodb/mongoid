require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::In do

  let(:base) do
    double
  end

  describe "#build" do

    let(:criteria) do
      Person.where(_id: object_id)
    end

    let(:metadata) do
      double(
        klass: Person,
        name: :person,
        foreign_key: "person_id",
        criteria: criteria
      )
    end

    let(:builder) do
      described_class.new(base, metadata, object)
    end

    context "when provided an id" do

      context "when the object is an object id" do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:object) do
          object_id
        end

        let(:person) do
          double
        end

        before do
          expect(criteria).to receive(:first).and_return(person)
        end

        let!(:document) do
          builder.build
        end

        it "sets the document" do
          expect(document).to eq(person)
        end
      end

      context "when the object is an integer" do

        before do
          Person.field :_id, overwrite: true, type: Integer
        end

        after do
          Person.field(
            :_id,
            overwrite: true,
            type: BSON::ObjectId,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new }
          )
        end

        let(:object_id) do
          666
        end

        let(:object) do
          object_id
        end

        let(:person) do
          double
        end

        before do
          expect(criteria).to receive(:first).and_return(person)
        end

        let!(:document) do
          builder.build
        end

        it "sets the document" do
          expect(document).to eq(person)
        end
      end
    end

    context "when provided a object" do

      let(:object) do
        Person.new
      end

      let(:builder) do
        described_class.new(base, nil, object)
      end

      let(:document) do
        builder.build
      end

      it "returns the object" do
        expect(document).to eq(object)
      end
    end
  end

  describe "#build" do

    let(:game) do
      Game.new
    end

    context "when no document found in the database" do

      context "when the id is nil" do

        it "returns nil" do
          expect(game.person).to be_nil
        end
      end

      context "when the id is incorrect" do

        before do
          game.person_id = BSON::ObjectId.new
        end

        it "returns nil" do
          expect(game.person).to be_nil
        end
      end
    end

    context "when the document is persisted" do

      let!(:person) do
        Person.create
      end

      let(:game) do
        Game.new(person_id: person.id)
      end

      it "returns the document" do
        expect(game.person).to eq(person)
      end
    end

    context 'setting an associated document to nil' do

      let(:person) do
        Person.create
      end

      let(:game) do
        Game.create(person: person)
      end

      before do
        game.person = nil
        game.save
      end

      it 'sets the person_id to nil' do
        expect(game.person_id).to be_nil
      end

      it 'does not delete the person' do
        expect(Person.find(person.id)).to eq(person)
      end
    end
  end

  describe '#substitute' do

    let(:person) do
      Person.create
    end

    let(:game) do
      Game.create(person: person)
    end

    context 'setting an associated document to nil' do

      before do
        game.person = nil
      end

      it 'sets the person_id to nil' do
        expect(game.person_id).to be_nil
      end

      it 'does not delete the person' do
        expect(Person.find(person.id)).to eq(person)
      end
    end

    context 'setting an associated document to other doc' do

      let(:other_person) do
        Person.create
      end

      before do
        game.person = other_person
      end

      it 'sets the person_id' do
        expect(game.person_id).to eq(other_person.id)
      end

      it 'does not delete the person' do
        expect(Person.find(person.id)).to eq(person)
      end
    end
  end
end
