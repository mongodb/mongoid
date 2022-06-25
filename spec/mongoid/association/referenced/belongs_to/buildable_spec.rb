# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Referenced::BelongsTo::Buildable do

  let(:base) do
    double
  end

  describe "#build" do

    let(:document) do
      association.build(base, object)
    end

    let(:options) do
      {}
    end

    let(:association) do
      Mongoid::Association::Referenced::BelongsTo.new(Post, :person, options)
    end

    context "when provided an id" do

      context "when the object is an object id" do

        let!(:person) do
          Person.create!(_id: object, username: 'Bob')
        end

        let(:object) do
          BSON::ObjectId.new
        end

        before do
          expect_any_instance_of(Mongoid::Criteria).to receive(:where).with(association.primary_key => object).and_call_original
        end

        it "sets the document" do
          expect(document).to eq(person)
        end
      end

      context "when scope is specified" do

        let!(:person) do
          Person.create(_id: object, username: 'Bob')
        end

        let(:object) do
          BSON::ObjectId.new
        end

        let(:options) do
          {
            scope: -> { where(username: 'Bob') }
          }
        end

        context "when document satisfies scope" do

          it "sets the document" do
            expect(document).to eq(person)
          end
        end

        context "when document does not satisfy scope" do

          let!(:person) do
            Person.create(_id: object, username: 'Bruce')
          end

          it "returns nil" do
            expect(document).to eq(nil)
          end
        end
      end

      context 'when the id is nil' do

        let(:object) do
          nil
        end

        before do
          expect(Person).not_to receive(:where)
        end

        it 'returns nil' do
          expect(document).to be_nil
        end
      end

      context "when the id does not correspond to a document in the database" do

        let!(:person) do
          Person.create!
        end

        let(:object) do
          BSON::ObjectId.new
        end

        before do
          expect_any_instance_of(Mongoid::Criteria).to receive(:where).with(association.primary_key => object).and_call_original
        end

        it 'returns nil' do
          expect(document).to be_nil
        end
      end

      context "when the object is an integer" do

        let!(:person) do
          Person.create!(_id: object)
        end

        let(:object) do
          666
        end

        before do
          expect_any_instance_of(Mongoid::Criteria).to receive(:where).with(association.primary_key => object).and_call_original
        end

        it "sets the document" do
          expect(document).to eq(person)
        end
      end
    end

    context "when provided a object" do

      let!(:person) do
        Person.create!
      end

      let(:object) do
        Person.new
      end

      before do
        expect_any_instance_of(Mongoid::Criteria).not_to receive(:where)
      end

      it "returns the object" do
        expect(document).to eq(object)
      end
    end

    context "when the document is persisted" do

      let!(:person) do
        Person.create!
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
        Person.create!
      end

      let(:game) do
        Game.create!(person: person)
      end

      before do
        game.person = nil
        game.save!
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
      Person.create!
    end

    let(:game) do
      Game.create!(person: person)
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
        Person.create!
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

  context 'when the object is already associated with another object' do

    context "when inverse is has_many" do

      let(:drug1) do
        Drug.create!
      end

      let(:drug2) do
        Drug.create!
      end

      let(:person) do
        Person.create!
      end

      before do
        drug1.person = person
        drug2.person = person
      end

      it 'does not clear the object of its previous association' do
        expect(drug1.person).to eq(person)
        expect(drug2.person).to eq(person)
        expect(person.drugs).to eq([drug1, drug2])
      end
    end

    context "when inverse is has_one" do

      let(:account1) do
        Account.create!(name: "1")
      end

      let(:account2) do
        Account.create!(name: "2")
      end

      let(:person) do
        Person.create!
      end

      before do
        account1.person = person
        account2.person = person
      end

      it 'clears the object of its previous association' do
        expect(account1.person).to be_nil
        expect(account2.person).to eq(person)
      end
    end
  end
end
