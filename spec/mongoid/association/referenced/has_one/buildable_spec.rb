# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Referenced::HasOne::Buildable do

  let(:base) do
    double(new_record?: false)
  end

  describe "#build" do

    let(:document) do
      association.build(base, object)
    end

    let(:options) do
      {}
    end

    let(:association) do
      Mongoid::Association::Referenced::HasOne.new(Person, :account, options)
    end

    context "when provided an id" do

      let!(:account) do
        Account.create!(person_id: object, name: 'banking', balance: 200)
      end

      let(:object) do
        BSON::ObjectId.new
      end

      before do
        expect_any_instance_of(Mongoid::Criteria).to receive(:where).with(association.foreign_key => object).and_call_original
      end

      it "sets the document" do
        expect(document).to eq(account)
      end
    end

    context "when scope is specified" do

      let!(:account) do
        Account.create!(person_id: object, name: 'banking', balance: 200)
      end

      let(:object) do
        BSON::ObjectId.new
      end

      let(:options) do
        {
            scope: -> { gt(balance: 100) }
        }
      end

      before do
        expect_any_instance_of(Mongoid::Criteria).to receive(:where).with(association.foreign_key => object).and_call_original
        expect_any_instance_of(Mongoid::Criteria).to receive(:gt).with(balance: 100).and_call_original
      end

      context "when document satisfies scope" do

        it "sets the document" do
          expect(document).to eq(account)
        end
      end

      context "when document does not satisfy scope" do

        let!(:account) do
          Account.create!(person_id: object, name: 'banking', balance: 50)
        end

        it "returns nil" do
          expect(document).to eq(nil)
        end
      end
    end

    context "when provided a object" do

      let(:object) do
        Account.new
      end

      it "returns the object" do
        expect(document).to eq(object)
      end

      context 'when the object is already associated with another object' do

        let(:original_person) do
          Person.new
        end

        let(:object) do
          Account.new(person: original_person)
        end

        let!(:document) do
          association.build(Person.new, object)
        end

        it 'clears the object of its previous association' do
          expect(original_person.account).to be_nil
        end

        it 'returns the object' do
          expect(document).to eq(object)
        end
      end
    end

    context "when the document is not found" do

      let(:object) do
        BSON::ObjectId.new
      end

      it "returns nil" do
        expect(document).to be_nil
      end
    end

    context "when the document is persisted" do

      let(:person) do
        Person.create!
      end

      let!(:game) do
        Game.create!(person: person)
      end

      it "returns the document" do
        expect(person.game).to eq(game)
      end
    end

    context "when the document have a non standard pk" do

      let(:person) do
        Person.create!
      end

      let!(:cat) do
        Cat.create!(person: person)
      end

      it "returns the document" do
        expect(person.cat).to eq(cat)
      end
    end
  end
end
